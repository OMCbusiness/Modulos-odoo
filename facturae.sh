#!/bin/bash

read -p "Por favor, introduce la versión de Odoo para instalar facturae(por ejemplo, 15): " version
read -p "Quiere la version arreglada de facturae? (s/n): " fixed

if [[ -z "$version" ]]; then
    echo "Debe ingresar una versión de Odoo."
    exit 1
fi

odoo_version="$version.0"

cd /opt/odoo/odoo$version-custom-addons

rm -rf l10n_es_partner
rm -rf l10n_es_facturae
rm -rf l10n_es_aeat
rm -rf base_iso3166
rm -rf base_bank_from_iban
rm -rf report_qweb_parameter
rm -rf report_xml
rm -rf account_payment_partner
rm -rf account_payment_mode
rm -rf account_tax_balance 
rm -rf date_range

git clone https://github.com/OCA/l10n-spain.git --branch $odoo_version --depth 1
mv l10n-spain/l10n_es_partner .
mv l10n-spain/l10n_es_facturae .
mv l10n-spain/l10n_es_aeat .
rm -rf l10n-spain

if [ "$fixed" == "s" ]; then
    rm -rf l10n_es_facturae/data/account_tax_template.xml
    mv ~/auto/fixes/account_tax_template.xml ./l10n_es_facturae/data/
fi

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

odoo_venv="/opt/odoo/odoo$version-venv"

source $odoo_venv/bin/activate
pip install unidecode
pip install pycountry
pip install xmlsig
pip install pyOpenSSL
pip install schwifty
deactivate

systemctl restart odoo$version

echo "INSTALACIÓN DE FACTURAE COMPLETADA CORRECTAMENTE!"
