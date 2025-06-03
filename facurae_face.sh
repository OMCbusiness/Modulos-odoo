#!/bin/bash

read -p "Por favor, introduce la versión de Odoo para instalar FACE (por ejemplo, 15): " version
read -p "¿Quiere la versión arreglada de FACE? (s/n): " fixed

if [[ -z "$version" ]]; then
    echo "Debe ingresar una versión de Odoo."
    exit 1
fi

odoo_version="$version.0"

custom_addons_dir="/opt/odoo/odoo${version}-custom-addons"
odoo_venv="/opt/odoo/odoo${version}-venv"

# Directorio addons custom
cd "$custom_addons_dir" || { echo "Directorio $custom_addons_dir no encontrado"; exit 1; }

# Limpiar módulos previos
rm -rf l10n_es_facturae_face l10n_es_facturae l10n_es_aeat l10n_es_partner \
       base_iso3166 base_bank_from_iban report_qweb_parameter report_xml \
       account_payment_partner account_payment_mode account_tax_balance date_range

# Clonar módulos necesarios (OCA repositorio l10n-spain y otros)
echo "Descargando módulos base y dependencias..."

git clone https://github.com/OCA/l10n-spain.git --branch $odoo_version --depth 1
mv l10n-spain/l10n_es_facturae_face .
mv l10n-spain/l10n_es_facturae .
mv l10n-spain/l10n_es_aeat .
mv l10n-spain/l10n_es_partner .
rm -rf l10n-spain

git clone https://github.com/OCA/community-data-files.git --branch $odoo_version --depth 1
mv community-data-files/base_iso3166 .
mv community-data-files/base_bank_from_iban .
rm -rf community-data-files

git clone https://github.com/OCA/reporting-engine.git --branch $odoo_version --depth 1
mv reporting-engine/report_qweb_parameter .
mv reporting-engine/report_xml .
rm -rf reporting-engine

git clone https://github.com/OCA/bank-payment.git --branch $odoo_version --depth 1
mv bank-payment/account_payment_partner .
mv bank-payment/account_payment_mode .
rm -rf bank-payment

git clone https://github.com/OCA/account-financial-reporting.git --branch $odoo_version --depth 1
mv account-financial-reporting/account_tax_balance .
rm -rf account-financial-reporting

git clone https://github.com/OCA/server-ux.git --branch $odoo_version --depth 1
mv server-ux/date_range .
rm -rf server-ux

# Aplicar FIX si se desea
if [ "$fixed" == "s" ]; then
    echo "Aplicando fixes al módulo l10n_es_facturae_face..."
    cp ~/auto/fixes/face_fix.xml ./l10n_es_facturae_face/data/ 2>/dev/null || echo "Fix no encontrado o no copiado."
fi

# Activar entorno virtual y instalar dependencias python
if [ -d "$odoo_venv" ]; then
    source $odoo_venv/bin/activate
    pip install unidecode pycountry xmlsig pyOpenSSL schwifty || true
    deactivate
else
    echo "El entorno virtual de Odoo no fue encontrado en $odoo_venv"
    exit 1
fi

# Reiniciar servicio Odoo
systemctl restart odoo$version

echo "INSTALACIÓN DE FACE (l10n_es_facturae_face) Y DEPENDENCIAS COMPLETADA CORRECTAMENTE!"
