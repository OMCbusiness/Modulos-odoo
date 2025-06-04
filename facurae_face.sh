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

cd "$custom_addons_dir" || { echo "Directorio $custom_addons_dir no encontrado"; exit 1; }

# Limpiar módulos previos
rm -rf l10n_es_facturae_face l10n_es_facturae l10n_es_aeat l10n_es_partner \
       base_iso3166 base_bank_from_iban report_qweb_parameter report_xml \
       account_payment_partner account_payment_mode account_tax_balance date_range \
       edi_exchange_template_oca component edi_oca component_event base_edi queue_job edi_account_oca

echo "Descargando módulos base y dependencias..."

# Módulos de localización
git clone https://github.com/OCA/l10n-spain.git --branch $odoo_version --depth 1
mv l10n-spain/l10n_es_facturae_face .
mv l10n-spain/l10n_es_facturae .
mv l10n-spain/l10n_es_aeat .
mv l10n-spain/l10n_es_partner .
rm -rf l10n-spain

# Archivos de datos comunitarios
git clone https://github.com/OCA/community-data-files.git --branch $odoo_version --depth 1
mv community-data-files/base_iso3166 .
mv community-data-files/base_bank_from_iban .
rm -rf community-data-files

# Reporting
git clone https://github.com/OCA/reporting-engine.git --branch $odoo_version --depth 1
mv reporting-engine/report_qweb_parameter .
mv reporting-engine/report_xml .
rm -rf reporting-engine

# Pagos
git clone https://github.com/OCA/bank-payment.git --branch $odoo_version --depth 1
mv bank-payment/account_payment_partner .
mv bank-payment/account_payment_mode .
rm -rf bank-payment

# Informes financieros
git clone https://github.com/OCA/account-financial-reporting.git --branch $odoo_version --depth 1
mv account-financial-reporting/account_tax_balance .
rm -rf account-financial-reporting

# Utilidades del servidor
git clone https://github.com/OCA/server-ux.git --branch $odoo_version --depth 1
mv server-ux/date_range .
rm -rf server-ux

# DEPENDENCIAS ADICIONALES ACTUALIZADAS Y CORRECTAS

# edi-framework: edi_oca, edi_exchange_template_oca, edi_account_oca
git clone https://github.com/OCA/edi-framework.git --branch $odoo_version --depth 1
mv edi-framework/edi_exchange_template_oca .
mv edi-framework/edi_oca .
mv edi-framework/edi_account_oca .
rm -rf edi-framework

# connector: component, component_event
git clone https://github.com/OCA/connector.git --branch $odoo_version --depth 1
mv connector/component .
mv connector/component_event .
rm -rf connector

# edi: base_edi
git clone https://github.com/OCA/edi.git --branch $odoo_version --depth 1
mv edi/base_edi .
rm -rf edi

# queue: queue_job
git clone https://github.com/OCA/queue.git --branch $odoo_version --depth 1
mv queue/queue_job .
rm -rf queue

# Aplicar fixes si se solicita
if [ "$fixed" == "s" ]; then
    echo "Aplicando fixes al módulo l10n_es_facturae_face..."
    cp ~/auto/fixes/face_fix.xml ./l10n_es_facturae_face/data/ 2>/dev/null || echo "Fix no encontrado o no copiado."
fi

# Instalar dependencias Python necesarias
if [ -d "$odoo_venv" ]; then
    source $odoo_venv/bin/activate
    pip install unidecode pycountry xmlsig pyOpenSSL schwifty || true
    deactivate
else
    echo "El entorno virtual de Odoo no fue encontrado en $odoo_venv"
    exit 1
fi

# Reiniciar Odoo
systemctl restart odoo$version

echo "INSTALACIÓN DE FACE (l10n_es_facturae_face) Y TODAS LAS DEPENDENCIAS COMPLETADA CORRECTAMENTE!"
