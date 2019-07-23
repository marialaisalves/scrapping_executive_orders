# Criei um tibbles com informações sobre os mandatos
library(tibble)
nomepresidente <- c('Collor', 'FHC', 'FHC2', 'Lula', 'Lula2', 'Dilma', 'Dilma2', 'Bolsonaro')
mandato <- c(1, 1, 2, 1, 2, 1, 2, 1)
ano <- c(1990, 1995, 1999, 2003, 2007, 2011, 2015, 2019)
presidentes <- as_tibble(cbind(nomepresidente, mandato, ano))
rm(ano, mandato, nomepresidente)
colnames(presidentes) <- c('Nome', 'Mandato', 'Ano')
presidentes$Ano <- as.double(presidentes$Ano)

# Baixando os arquivos
URLs <- c('http://www4.planalto.gov.br/legislacao/portal-legis/legislacao-1/decretos1/1990-decretos-1',
          'http://www4.planalto.gov.br/legislacao/portal-legis/legislacao-1/decretos1/1995',
          'http://www4.planalto.gov.br/legislacao/portal-legis/legislacao-1/decretos1/1999-decretos-2',
          'http://www4.planalto.gov.br/legislacao/portal-legis/legislacao-1/decretos1/2003',
          'http://www4.planalto.gov.br/legislacao/portal-legis/legislacao-1/decretos1/2007',
          'http://www4.planalto.gov.br/legislacao/portal-legis/legislacao-1/decretos1/2011-decretos-2',
          'http://www4.planalto.gov.br/legislacao/portal-legis/legislacao-1/decretos1/2015-decretos-1',
          'http://www4.planalto.gov.br/legislacao/portal-legis/legislacao-1/decretos1/2019-decretos')
filename <- c('1990.html', '1995.html', '1999.html', '2003.html', '2007.html',
              '2011.html', '2015.html', '2019.html')
# Coloque aqui o caminho onde se encontra o seu binário do PhantomJS
bin_path <- '/home/mribeirodantas/node_modules/phantomjs/lib/phantom/bin/'

for (i in 1:length(presidentes$ano)) {
  system(paste0(bin_path, 'phantomjs scrap_js_generated_page.js ',
                URLs[i], ' ', filename[i]))
}
rm(i)

library(rvest)
library(tidyr)
library(dplyr)

# Função para descobrir qual o nome correto do campo
get_selector_data <- function(tb) {
  if (length(html_nodes(tb, '.visaoQuadrosTd')) == 0) {
    html_nodes(tb, '.primeiraColuna')
  } else {
    html_nodes(tb, '.visaoQuadrosTd')
  }
}
library(stringr)
library(lubridate)
# Minerando a data de todos os decretos dos arquivos baixados
decretos <- as_tibble()
for (file in list.files(pattern = '*.html$')) {
  webpage <- read_html(file)
  temp_decretos <- webpage %>%
    # Raspar todas as informações associadas com
    # esse seletor
    get_selector_data %>%
    str_extract('[0-9]{1,2}\\.\040{0,1}[0-9]{1,2}\\.(90|95|99|2003|2007|2011|2015|2019)') %>% 
    # Converta em tibble (estrutura de dados)
    as_tibble %>%
    # Remova NAs
    drop_na %>%
    # Parse para objeto de data do lubridate
    dmy(.$value) %>%
    # Remova os NAs
    na.omit %>%
    # Converta em tibble
    as_tibble
  decretos <- bind_rows(decretos, temp_decretos)
}
rm(temp_decretos, webpage)
# Quantos decrtos tem cada presidente no total nesse período?
color <- decretos %>%
  arrange(.$value) %>%
  filter(year(ymd(value)) == 1990) %>% nrow

# Construindo uma tabela mais informativa com os dados minerados
decretos <- decretos %>%
  arrange(.$value) %>% 
  mutate('Dia' = day(.$value)) %>%
  mutate('Mes' = month(.$value)) %>%
  mutate('Ano' = year(.$value))

decretos <- inner_join(x = presidentes, y = decretos, by = 'Ano')
rm(presidentes)
colnames(decretos) <- c('Presidente', 'Mandato', 'Ano', 'Publicado', 'Dia', 'Mes')

# Criando o campo nDecretos
n_decretos <- decretos %>%
  arrange(Ano) %>%
  group_by(Presidente) %>%
  summarise(n = n()) %>%
  right_join(., decretos, by = 'Presidente') %>%
  select(Presidente, n, Ano) %>%
  unique %>%
  select(n)
decretos <- decretos %>%
  mutate('nDecretos' = unlist(apply(n_decretos, 1, function (x) { seq(1:x) })))

# Filtrando pela data que utilizei no artigo (22/05/2019)
decretos_plot <- decretos %>%
  # filter(month(Publicado) <= month(today()))
  filter(month(Publicado) <= month(mdy('5.22.2019')))
# Removendo o período de 23 em diante do mês e Maio
decretos_plot <- decretos_plot %>%
  filter(!(month(Publicado) == 5 & day(Publicado) > 22))



# Visualização dos dados
library(ggplot2)
# Barplot
bar_plot <- decretos_plot %>%
  group_by(Presidente) %>%
  summarise(n())
colnames(bar_plot) <- c('Presidente', 'N')
# Essa linha é importante para que o gráfico
# de barras esteja com as barras ordenadas
bar_plot$Presidente <- factor(bar_plot$Presidente,
                              levels = bar_plot$Presidente[order(bar_plot$N)])
ggplot(bar_plot, aes(x=Presidente, y=N)) +
  geom_bar(stat="identity", fill='steelblue') +
  xlab('Mandato') + ylab('Número de decretos') +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(title = 'Decretos de 1 de Janeiro a 22 de Maio do primeiro ano de mandato',
       caption= "Marcel Ribeiro Dantas (2019). http://mribeirodantas.me")
# Adicionando linha horizontal com mediana
mediana <- decretos_plot %>%
  group_by(Presidente) %>%
  summarise(n()) %>%
  pull(`n()`) %>%
  median
ggplot(bar_plot, aes(x=Presidente,
                     y=N)) +
  geom_bar(stat="identity", fill='steelblue') +
  geom_hline(aes(yintercept=mediana), color="black") +
  xlab('Mandato') + ylab('Número de decretos') +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(title = 'Decretos de 1 de Janeiro a 22 de Maio do primeiro ano de mandato',
       caption= "Marcel Ribeiro Dantas (2019). http://mribeirodantas.me")


# Boxplot
ggplot(bar_plot, aes(y=N)) +
  geom_boxplot(fill="steelblue",
               outlier.color = 'red') +
  ylab('Número de decretos')


# Curva animada
library(directlabels)
decretos_plot <- decretos_plot %>% 
  mutate(ID = group_indices_(decretos_plot, .dots=c("Mes", "Dia")))

p <- ggplot(decretos_plot, aes(ID,
                               nDecretos,
                               group = Presidente,
                               color = Presidente)) +
  geom_line() +
  geom_hline(aes(yintercept=mediana), color="black") +
  labs(x = "De 1 de Janeiro a 22 de Maio do primeiro ano de mandato",
       y = "Número de decretos",
       caption = "Marcel Ribeiro Dantas (2019). http://mribeirodantas.me") +
  theme(legend.position = "top") +
  geom_dl(aes(label = decretos_plot$Presidente),
          method = list(dl.combine("last.points"))
  )

library(gganimate)
a <- p + transition_reveal(ID)
# A linha abaixo requer o gifski. O pacote costuma ser chamado cargo nas
# distribuições GNU/Linux. Com ele instalado, instal.packages('gifski')
anim <- animate(a, fps=8, renderer = gifski_renderer(loop = F))
anim_save(here::here("n_decretos.gif"))

# Facetas
ggplot(decretos_plot, aes(Mes)) +
  geom_bar(fill='steelblue') +
  facet_wrap(~Presidente) +
  xlab('Mês') +
  ylab('Número de decretos') +
  labs(caption = 'Marcel Ribeiro Dantas (2019). http://mribeirodantas.me')


# Barras empilhadas
decretos_plot %>%
  filter(Presidente != 'Collor') %>%
  group_by(Presidente,Mes) %>%
  count %>%
  ggplot() +
  geom_bar(aes(y=n,x=Mes,fill=Presidente), stat="identity") +
  labs(x = 'Mês', y = 'Número de decretos',
       caption = "Marcel Ribeiro Dantas (2019). http://mribeirodantas.me")


# Número de decretos por dia e por mandato de cada presidente
ggplot(decretos_plot, aes(ID)) +
  geom_bar(fill='steelblue') +
  facet_wrap(~Presidente) +
  xlab('Dia') +
  ylab('Número de decretos') +
  labs(caption = 'Marcel Ribeiro Dantas (2019). http://mribeirodantas.me')


# Mais estatísticas
decretos_plot %>%
  group_by(Mes) %>%
  arrange(Mes) %>% 
  filter(nDecretos == max(nDecretos)) %>% 
  select('Presidente', 'nDecretos')

decretos_plot %>%
  filter(Presidente != 'Collor') %>%
  group_by(Mes) %>%
  arrange(Mes) %>% 
  filter(nDecretos == max(nDecretos)) %>%
  select('Presidente', 'nDecretos', 'Mes', 'Ano')
