library(here)
library(dplyr)
library(lubridate)
library(ggplot2)
library(scales)


#########################################################################################
# Data Extraction #######################################################################
#########################################################################################

# Set JAVA_HOME, set max. memory, and load rJava library
java_version = config::get("java_version", file = "C:\\Users\\PoorJ\\Projects\\config.yml")
Sys.setenv(JAVA_HOME = java_version$JAVA_HOME)
options(java.parameters = "-Xmx2g")
library(rJava)

# Output Java version
.jinit()
print(.jcall("java/lang/System", "S", "getProperty", "java.version"))

# Load RJDBC library
library(RJDBC)

# Get credentials
datamnr <-
  config::get("datamnr", file = "C:\\Users\\PoorJ\\Projects\\config.yml")

# Create connection driver
jdbcDriver <-
  JDBC(driverClass = "oracle.jdbc.OracleDriver", classPath = "C:\\Users\\PoorJ\\Desktop\\ojdbc7.jar")

# Open connection: kontakt---------------------------------------------------------------
jdbcConnection <-
  dbConnect(
    jdbcDriver,
    url = datamnr$server,
    user = datamnr$uid,
    password = datamnr$pwd
  )

# Fetch data
covid_query <- "SELECT   DISTINCT
           ervenyesseg as idoszak,
           termekcsoport,
           CASE WHEN hatralek_ho in ('0', '1') THEN 'N' ELSE 'I' END AS hat_2_ho,
           CASE WHEN payment_method = 'Rendsz.bankkártya' then 'rendszeres bankkartyas' else CONVERT (payment_method, 'US7ASCII') end as payment_method,
           CONVERT (settlement_type, 'US7ASCII') as settlement_type,
           CONVERT (korcsoport, 'US7ASCII') as korcsoport,
           CONVERT (i_ertcsat, 'US7ASCII') as i_ertcsat,
           CONVERT (alldij_kat, 'US7ASCII') as alldij_kat,
           CONVERT (i_ertcsat, 'US7ASCII') as i_ertcsat,
           sum(elo_szerzodes_db) as darab
    FROM   wagnerj.covid_his_adatok
    WHERE hatralek_ho <> 'hiba'
    AND termekcsoport is not null
    AND termekcsoport <> 'KISALLAT'
    AND payment_method is not null
    AND settlement_type is not null
    AND i_ertcsat is not null
    AND alldij_kat is not null
    group by ervenyesseg,
           termekcsoport,
           CASE WHEN hatralek_ho in ('0', '1') THEN 'N' ELSE 'I' END,
           CASE WHEN payment_method = 'Rendsz.bankkártya' then 'rendszeres bankkartyas' else CONVERT (payment_method, 'US7ASCII') end,
           CONVERT (settlement_type, 'US7ASCII'),
           CONVERT (korcsoport, 'US7ASCII'),
           CONVERT (i_ertcsat, 'US7ASCII'),
           CONVERT (alldij_kat, 'US7ASCII'),
           CONVERT (i_ertcsat, 'US7ASCII')
ORDER BY   2, 1, 3"

covid_df <- dbGetQuery(jdbcConnection, covid_query)

# Close db connection: kontakt
dbDisconnect(jdbcConnection)


covid_df <-
  covid_df %>% mutate(IDOSZAK = ymd_hms(IDOSZAK))


write.csv(covid_df, here::here("Data", "covid_df"), row.names = FALSE)


# Testing

# covid_df <- read.csv(here::here("Data", "covid_df"),
#                      stringsAsFactors = FALSE)
# 
# 
# test <- covid_df %>%
#   group_by(IDOSZAK, TERMEKCSOPORT, HAT_2_HO) %>% 
#   summarize(DARAB = sum(DARAB)) %>% 
#   ungroup() %>% 
#   group_by(IDOSZAK, TERMEKCSOPORT) %>% 
#   mutate(TOTAL = sum(DARAB)) %>% 
#   mutate(HATRALEKOS_ARANY = DARAB / TOTAL) %>% 
#   ungroup() %>% 
#   filter(HAT_2_HO == 'I') %>% 
#   mutate(IDOSZAK = as.Date(IDOSZAK)) %>% 
#   select(IDOSZAK, TERMEKCSOPORT, HATRALEKOS_ARANY) %>% 
#   arrange(TERMEKCSOPORT, IDOSZAK)
# 
# 
# ggplot(test, aes(IDOSZAK, HATRALEKOS_ARANY)) +
#   geom_point() +
#   geom_smooth() +
#   facet_wrap(~TERMEKCSOPORT, ncol = 4, scales = "free")

##########################################################################################
# Push app to shinyapps.io ###############################################################
# ########################################################################################

Sys.setenv(http_proxy = proxy$http)
Sys.setenv(https_proxy = proxy$http)

rsconnect::deployApp(appName = "Covid2", forceUpdate = TRUE)