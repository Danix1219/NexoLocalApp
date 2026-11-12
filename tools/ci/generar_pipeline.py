#!/usr/bin/env python3
"""Genera .github/workflows/app-ci.yml y infra/github/checks.auto.tfvars.json.

Una prueba = un job. Así el grafo de GitHub Actions muestra cada archivo de
prueba por separado y la protección de ramas (Terraform) exige cada uno.

Uso (desde la raíz del repo):
    python3 tools/ci/generar_pipeline.py          # escribe los archivos
    python3 tools/ci/generar_pipeline.py --check  # falla si no están al día

Spec 047. Si agregas un archivo *_test.dart, vuelve a correrlo y haz commit.
"""
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
APP = "src/mobile/nexo_app"
WORKFLOW = ROOT / ".github/workflows/app-ci.yml"
CHECKS = ROOT / "infra/github/checks.auto.tfvars.json"

SHA = {
    "checkout": "actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2",
    "upload": "actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02 # v4.6.2",
    "download": "actions/download-artifact@9000827ccba6bdab643e8b6fd33ac0654aef8333 # v8.0.2",
    "java": "actions/setup-java@c5195efecf7bdfc987ee8bae7a71cb8b11521c00 # v4.7.1",
    "gitleaks": "gitleaks/gitleaks-action@ff98106e4c7b2bc287b24eaf42907196329070c7 # v2.3.9",
    "osv": "google/osv-scanner-action/osv-scanner-action@b1d267aea5211fa648d9d442fa64b90dbdcbdd36 # v2.7.0",
    "depreview": "actions/dependency-review-action@a1d282b36b6f3519aa1f3fc636f609c47dddb294 # v5.0.0",
    "play": "r0adkll/upload-google-play@e738b9dd8f2476ea806d921b64aacd24f34515a5 # v1.1.5",
}

LAYERS = [
    ("unit", "unidad", "Unidad"),
    ("integration", "integracion", "Integración"),
    ("security", "seguridad", "Seguridad"),
]


def tests(layer):
    folder = ROOT / APP / "test" / layer
    return sorted(p for p in folder.glob("*_test.dart"))


def slug(path):
    return path.stem[: -len("_test")].replace("_", "-")


class Y:
    """Emisor YAML mínimo con sangría controlada (sin dependencias)."""

    def __init__(self):
        self.lines = []

    def __call__(self, text="", indent=0):
        self.lines.append(("  " * indent + text).rstrip())

    def text(self):
        return "\n".join(self.lines) + "\n"


def flutter_steps(y, ind):
    y("- name: Descargar el código", ind)
    y(f"  uses: {SHA['checkout']}", ind)
    y("  with:", ind)
    y("    persist-credentials: false", ind)
    y("- name: Preparar Flutter y dependencias", ind)
    y("  uses: ./.github/actions/flutter", ind)


def job(y, jid, name, needs=None, cond=None, env_name=None, timeout=15, permissions=None):
    y(f"{jid}:", 1)
    y(f"name: {json.dumps(name, ensure_ascii=False)}", 2)
    if needs:
        y(f"needs: [{', '.join(needs)}]", 2)
    if cond:
        y(f"if: {cond}", 2)
    if env_name:
        y(f"environment: {env_name}", 2)
    if permissions:
        y("permissions:", 2)
        for k, v in permissions.items():
            y(f"{k}: {v}", 3)
    y("runs-on: ubuntu-latest", 2)
    y(f"timeout-minutes: {timeout}", 2)


def build():
    y = Y()
    checks = []
    y("# GENERADO por tools/ci/generar_pipeline.py (spec 047). No editar a mano.")
    y("# Cada archivo de prueba es un job: el grafo muestra cada prueba por separado.")
    y("name: App CI/CD")
    y("on:")
    y("push:", 1)
    y("branches: [develop, main, 'release/**', 'feature/**', 'fix/**']", 2)
    y("pull_request:", 1)
    y("branches: [develop, main, 'release/**']", 2)
    y("workflow_dispatch:", 1)
    y("inputs:", 2)
    y("publicar:", 3)
    y("description: 'Publicar en Play Store (pista según la rama)'", 4)
    y("type: boolean", 4)
    y("default: false", 4)
    y("permissions:")
    y("contents: read", 1)
    y("concurrency:")
    y("group: app-ci-${{ github.ref }}", 1)
    y("cancel-in-progress: ${{ github.event_name == 'pull_request' }}", 1)
    y("env:")
    y(f"APP_DIR: {APP}", 1)
    y("jobs:")

    # 1 · Preparación y gobierno del pipeline
    job(y, "pipeline", "Pipeline · al día con las pruebas", timeout=5)
    y("steps:", 2)
    y("- name: Descargar el código", 3)
    y(f"  uses: {SHA['checkout']}", 3)
    y("  with:", 3)
    y("    persist-credentials: false", 3)
    y("- name: Cada archivo de prueba tiene su job", 3)
    y("  run: python3 tools/ci/generar_pipeline.py --check", 3)
    checks.append("Pipeline · al día con las pruebas")

    job(y, "preparar", "Preparar · Flutter y dependencias", needs=["pipeline"], timeout=15)
    y("defaults:", 2)
    y("run:", 3)
    y("working-directory: ${{ env.APP_DIR }}", 4)
    y("steps:", 2)
    flutter_steps(y, 3)
    y("- name: Versiones", 3)
    y("  run: flutter --version && dart --version", 3)
    checks.append("Preparar · Flutter y dependencias")

    # 2 · Calidad estática
    for jid, name, cmd in [
        ("formato", "Calidad · formato", "dart format --output=none --set-exit-if-changed lib test"),
        ("analisis", "Calidad · análisis estático", "flutter analyze --no-fatal-infos"),
    ]:
        job(y, jid, name, needs=["preparar"], timeout=15)
        y("defaults:", 2)
        y("run:", 3)
        y("working-directory: ${{ env.APP_DIR }}", 4)
        y("steps:", 2)
        flutter_steps(y, 3)
        y(f"- name: {name}", 3)
        y(f"  run: {cmd}", 3)
        checks.append(name)

    # 3 · Pruebas: un job por archivo
    test_jobs = {}
    for layer, prefix, label in LAYERS:
        ids = []
        if layer == "unit":
            needs = ["formato", "analisis"]
        elif layer == "integration":
            needs = test_jobs["unit"]
        else:
            needs = ["analisis"]
        for t in tests(layer):
            s = slug(t)
            jid = f"{prefix}-{s}"
            name = f"{label} · {s}"
            rel = t.relative_to(ROOT / APP).as_posix()
            job(y, jid, name, needs=needs, timeout=20)
            y("defaults:", 2)
            y("run:", 3)
            y("working-directory: ${{ env.APP_DIR }}", 4)
            y("steps:", 2)
            flutter_steps(y, 3)
            y(f"- name: flutter test {rel}", 3)
            y(f"  run: flutter test --coverage --coverage-path=coverage/{jid}.lcov --reporter=expanded {rel}", 3)
            y("- name: Guardar cobertura", 3)
            y("  if: always()", 3)
            y(f"  uses: {SHA['upload']}", 3)
            y("  with:", 3)
            y(f"    name: cov-{jid}", 3)
            y(f"    path: ${{{{ env.APP_DIR }}}}/coverage/{jid}.lcov", 3)
            y("    if-no-files-found: ignore", 3)
            y("    retention-days: 7", 3)
            ids.append(jid)
            checks.append(name)
        test_jobs[layer] = ids
        if not ids:
            raise SystemExit(f"No hay pruebas en test/{layer}: cada capa debe tener al menos una.")

    # 4 · Seguridad de herramientas (además de las pruebas Dart de seguridad)
    job(y, "seguridad-secretos", "Seguridad · secretos en el historial (gitleaks)", needs=["pipeline"], timeout=10)
    y("steps:", 2)
    y("- name: Descargar el código con historial", 3)
    y(f"  uses: {SHA['checkout']}", 3)
    y("  with:", 3)
    y("    fetch-depth: 0", 3)
    y("    persist-credentials: false", 3)
    y("- name: gitleaks", 3)
    y(f"  uses: {SHA['gitleaks']}", 3)
    y("  env:", 3)
    y("    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}", 3)
    checks.append("Seguridad · secretos en el historial (gitleaks)")

    job(y, "seguridad-dependencias", "Seguridad · vulnerabilidades en dependencias (OSV)", needs=["preparar"], timeout=10)
    y("steps:", 2)
    y("- name: Descargar el código", 3)
    y(f"  uses: {SHA['checkout']}", 3)
    y("  with:", 3)
    y("    persist-credentials: false", 3)
    y("- name: osv-scanner sobre pubspec.lock", 3)
    y(f"  uses: {SHA['osv']}", 3)
    y("  with:", 3)
    y("    scan-args: |-", 3)
    y(f"      --lockfile={APP}/pubspec.lock", 3)
    checks.append("Seguridad · vulnerabilidades en dependencias (OSV)")

    job(y, "seguridad-manifest", "Seguridad · AndroidManifest y build", needs=["pipeline"], timeout=5)
    y("steps:", 2)
    y("- name: Descargar el código", 3)
    y(f"  uses: {SHA['checkout']}", 3)
    y("  with:", 3)
    y("    persist-credentials: false", 3)
    y("- name: Revisar permisos, respaldo y tráfico en claro", 3)
    y(f"  run: python3 tools/ci/revisar_android.py {APP}", 3)
    checks.append("Seguridad · AndroidManifest y build")

    job(y, "seguridad-workflows", "Seguridad · workflows (actionlint y permisos)", needs=["pipeline"], timeout=10)
    y("steps:", 2)
    y("- name: Descargar el código", 3)
    y(f"  uses: {SHA['checkout']}", 3)
    y("  with:", 3)
    y("    persist-credentials: false", 3)
    y("- name: actionlint v1.7.7", 3)
    y("  run: |", 3)
    y("    go install github.com/rhysd/actionlint/cmd/actionlint@v1.7.7", 3)
    y('    "$(go env GOPATH)/bin/actionlint" -color', 3)
    y("- name: Acciones fijadas por SHA y permisos mínimos", 3)
    y("  run: python3 tools/ci/revisar_workflows.py", 3)
    checks.append("Seguridad · workflows (actionlint y permisos)")

    job(y, "seguridad-revision-dependencias", "Seguridad · revisión de dependencias del PR",
        needs=["pipeline"], cond="github.event_name == 'pull_request'", timeout=5,
        permissions={"contents": "read", "pull-requests": "read"})
    y("steps:", 2)
    y(f"- uses: {SHA['depreview']}", 3)
    y("  with:", 3)
    y("    fail-on-severity: high", 3)
    checks.append("Seguridad · revisión de dependencias del PR")

    job(y, "version", "Versión · matriz y SemVer", needs=["pipeline"], timeout=5)
    y("outputs:", 2)
    y("app_version: ${{ steps.v.outputs.app_version }}", 3)
    y("steps:", 2)
    y("- name: Descargar el código", 3)
    y(f"  uses: {SHA['checkout']}", 3)
    y("  with:", 3)
    y("    persist-credentials: false", 3)
    y("- name: Versión del pubspec en docs/versionamiento.md y rama release", 3)
    y("  id: v", 3)
    y("  run: python3 tools/ci/versionamiento.py", 3)
    checks.append("Versión · matriz y SemVer")

    sec_tools = ["seguridad-secretos", "seguridad-dependencias", "seguridad-manifest", "seguridad-workflows",
                 "seguridad-revision-dependencias"]

    # 5 · Cobertura combinada
    all_tests = test_jobs["unit"] + test_jobs["integration"] + test_jobs["security"]
    job(y, "cobertura", "Calidad · cobertura combinada", needs=all_tests, timeout=10)
    y("steps:", 2)
    y("- name: Descargar el código", 3)
    y(f"  uses: {SHA['checkout']}", 3)
    y("  with:", 3)
    y("    persist-credentials: false", 3)
    y("- name: Juntar la cobertura de cada prueba", 3)
    y(f"  uses: {SHA['download']}", 3)
    y("  with:", 3)
    y("    pattern: cov-*", 3)
    y("    path: cobertura", 3)
    y("    merge-multiple: true", 3)
    y("- name: Umbral de la constitución (§8)", 3)
    y("  run: python3 tools/ci/cobertura.py cobertura --min ${{ vars.MIN_COVERAGE || '45' }} | tee -a \"$GITHUB_STEP_SUMMARY\"", 3)
    checks.append("Calidad · cobertura combinada")

    # 6 · Construcción de prueba
    job(y, "apk", "Construir · APK de prueba", needs=["cobertura", "version"] + sec_tools[:-1], timeout=30)
    y("defaults:", 2)
    y("run:", 3)
    y("working-directory: ${{ env.APP_DIR }}", 4)
    y("steps:", 2)
    flutter_steps(y, 3)
    y("- name: Java 17", 3)
    y(f"  uses: {SHA['java']}", 3)
    y("  with:", 3)
    y("    distribution: temurin", 3)
    y("    java-version: '17'", 3)
    y("- name: APK debug en modo auto (backend o datos de ejemplo)", 3)
    y("  run: >-", 3)
    y("    flutter build apk --debug", 3)
    y("    --dart-define=API_BASE_URL=${{ vars.API_BASE_URL }}", 3)
    y("    --dart-define=LANDING_URL=${{ vars.LANDING_URL }}", 3)
    y("    --dart-define=APP_VERSION=${{ needs.version.outputs.app_version }}", 3)
    y("- name: Guardar APK", 3)
    y(f"  uses: {SHA['upload']}", 3)
    y("  with:", 3)
    y("    name: apk-debug", 3)
    y("    path: ${{ env.APP_DIR }}/build/app/outputs/flutter-apk/app-debug.apk", 3)
    y("    retention-days: 14", 3)
    checks.append("Construir · APK de prueba")

    # 7 · Compuerta final
    gate_needs = ["pipeline", "preparar", "formato", "analisis", "version"] + all_tests + sec_tools + ["cobertura", "apk"]
    job(y, "ci-verde", "CI · todo verde", needs=gate_needs, cond="always()", timeout=5)
    y("steps:", 2)
    y("- name: Descargar el código", 3)
    y(f"  uses: {SHA['checkout']}", 3)
    y("  with:", 3)
    y("    persist-credentials: false", 3)
    y("- name: Ninguna prueba falló ni se canceló", 3)
    y("  env:", 3)
    y("    RESULTADOS: ${{ toJSON(needs) }}", 3)
    y("  run: python3 tools/ci/compuerta.py", 3)
    checks.append("CI · todo verde")

    # 8 · Entrega continua (solo ramas de entrega)
    deliver = ("github.event_name != 'pull_request' && (github.ref == 'refs/heads/main' || "
               "startsWith(github.ref, 'refs/heads/release/')) && "
               "(github.event_name == 'push' || inputs.publicar)")
    job(y, "aab", "Construir · AAB firmado", needs=["ci-verde", "version"], cond=deliver, timeout=40, env_name="firma")
    y("defaults:", 2)
    y("run:", 3)
    y("working-directory: ${{ env.APP_DIR }}", 4)
    y("steps:", 2)
    flutter_steps(y, 3)
    y("- name: Java 17", 3)
    y(f"  uses: {SHA['java']}", 3)
    y("  with:", 3)
    y("    distribution: temurin", 3)
    y("    java-version: '17'", 3)
    y("- name: La URL del backend de release es HTTPS", 3)
    y("  env:", 3)
    y("    URL: ${{ vars.API_BASE_URL }}", 3)
    y("  run: |", 3)
    y("    case \"$URL\" in https://*) echo \"OK $URL\";; *) echo \"::error::API_BASE_URL debe ser https://\"; exit 1;; esac", 3)
    y("- name: Aviso de privacidad en la landing (HTTPS)", 3)
    y("  env:", 3)
    y("    URL: ${{ vars.LANDING_URL }}", 3)
    y("  run: |", 3)
    y("    case \"$URL\" in https://*) echo \"OK $URL\";; *) echo \"::error::Define LANDING_URL (https) para el aviso de privacidad\"; exit 1;; esac", 3)
    y("- name: Firebase para push (google-services.json desde secretos)", 3)
    y("  env:", 3)
    y("    GOOGLE_SERVICES_JSON: ${{ secrets.GOOGLE_SERVICES_JSON }}", 3)
    y("    ANDROID_PACKAGE_NAME: ${{ vars.ANDROID_PACKAGE_NAME || 'mx.nexolocal.app' }}", 3)
    y("  run: python3 ../../../tools/ci/preparar_firebase.py android", 3)
    y("- name: Firma de subida (keystore desde secretos)", 3)
    y("  env:", 3)
    y("    KEYSTORE_B64: ${{ secrets.ANDROID_KEYSTORE_BASE64 }}", 3)
    y("    STORE_PASSWORD: ${{ secrets.ANDROID_KEYSTORE_PASSWORD }}", 3)
    y("    KEY_ALIAS: ${{ secrets.ANDROID_KEY_ALIAS }}", 3)
    y("    KEY_PASSWORD: ${{ secrets.ANDROID_KEY_PASSWORD }}", 3)
    y("  run: python3 ../../../tools/ci/preparar_firma.py android", 3)
    y("- name: AAB release", 3)
    y("  run: >-", 3)
    y("    flutter build appbundle --release", 3)
    y("    --build-number=$(( ${{ github.run_number }} + ${{ vars.BUILD_NUMBER_OFFSET || 1000 }} ))", 3)
    y("    --dart-define=API_BASE_URL=${{ vars.API_BASE_URL }}", 3)
    y("    --dart-define=API_MODE=${{ vars.API_MODE || 'auto' }}", 3)
    y("    --dart-define=LANDING_URL=${{ vars.LANDING_URL }}", 3)
    y("    --dart-define=APP_VERSION=${{ needs.version.outputs.app_version }}", 3)
    y("    --obfuscate --split-debug-info=build/simbolos", 3)
    y("- name: Borrar la llave del runner", 3)
    y("  if: always()", 3)
    y("  run: rm -f android/key.properties android/app/upload-keystore.jks android/app/google-services.json", 3)
    y("- name: Guardar AAB y símbolos", 3)
    y(f"  uses: {SHA['upload']}", 3)
    y("  with:", 3)
    y("    name: aab-release", 3)
    y("    path: |", 3)
    y("      ${{ env.APP_DIR }}/build/app/outputs/bundle/release/app-release.aab", 3)
    y("      ${{ env.APP_DIR }}/build/simbolos", 3)
    y("    retention-days: 30", 3)

    for jid, name, track, cond_ref, env_name in [
        ("play-interna", "Play Store · pruebas internas", "internal",
         "startsWith(github.ref, 'refs/heads/release/')", "staging"),
        ("play-produccion", "Play Store · producción", "production", "github.ref == 'refs/heads/main'", "production"),
    ]:
        job(y, jid, name, needs=["aab"], cond=cond_ref, env_name=env_name, timeout=15)
        y("steps:", 2)
        y("- name: Descargar AAB", 3)
        y(f"  uses: {SHA['download']}", 3)
        y("  with:", 3)
        y("    name: aab-release", 3)
        y("    path: salida", 3)
        y(f"- name: Subir a la pista {track}", 3)
        y(f"  uses: {SHA['play']}", 3)
        y("  with:", 3)
        y("    serviceAccountJsonPlainText: ${{ secrets.PLAY_SERVICE_ACCOUNT_JSON || secrets.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON }}", 3)
        y("    packageName: ${{ vars.ANDROID_PACKAGE_NAME || 'mx.nexolocal.app' }}", 3)
        y("    releaseFiles: salida/app/outputs/bundle/release/app-release.aab", 3)
        y(f"    track: {track}", 3)
        # Una app que aún no se publica en Play solo acepta "draft".
        y("    status: ${{ vars.PLAY_STATUS || 'draft' }}", 3)

    return y.text(), checks


def main():
    text, checks = build()
    checks = ["SDD / docs", "Git / flow"] + checks
    payload = json.dumps({"required_checks": checks}, ensure_ascii=False, indent=2) + "\n"
    if "--check" in sys.argv:
        stale = []
        if not WORKFLOW.exists() or WORKFLOW.read_text(encoding="utf-8") != text:
            stale.append(str(WORKFLOW.relative_to(ROOT)))
        if not CHECKS.exists() or CHECKS.read_text(encoding="utf-8") != payload:
            stale.append(str(CHECKS.relative_to(ROOT)))
        if stale:
            print("Desactualizado: " + ", ".join(stale))
            print("Corre: python3 tools/ci/generar_pipeline.py y haz commit.")
            sys.exit(1)
        print(f"PIPELINE-OK: {len(checks)} checks requeridos; un job por archivo de prueba.")
        return
    WORKFLOW.parent.mkdir(parents=True, exist_ok=True)
    CHECKS.parent.mkdir(parents=True, exist_ok=True)
    WORKFLOW.write_text(text, encoding="utf-8")
    CHECKS.write_text(payload, encoding="utf-8")
    print(f"Escrito {WORKFLOW.relative_to(ROOT)} ({len(checks)} checks) y {CHECKS.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
