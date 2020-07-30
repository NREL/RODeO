









library(DBI)
library(plyr)
library(dplyr)
library(tidyr) #vignette("tidy-data")



# connect to the sqlite file
con = dbConnect(RSQLite::SQLite(), dbname="gamsdir/projdir/RODeO/Output/Default_summary.db")
#con = dbConnect(drv="SQLite", dbname="gamsdir/projdir/RODeO/Output/Default_summary.db")
# get a list of all tables
alltables = dbListTables(con)
# get the populationtable as a data.frame
p1 = dbGetQuery( con,'select * from Scenarios' )
# count the areas in the SQLite table
p2 = dbGetQuery( con,'select * from Summary' )
p3 = join(p1, p2, by='Scenario Number')
p3 = cbind(p3,data.frame(timed.dem.charge=rowSums(select(p3,57:62)))) 
names(p3)[71]='Timed demand charge ($)'

column_names = data.frame(Properties = colnames(p3))
p3 = p3[ , !(names(p3) %in% column_names$Properties[57:62])]

p4 <- p3 %>% gather(Cost.Properties, Values, 49:57, 59:65)
column_names = data.frame(Properties = colnames(p4))


######## Plot stacked bar chart #######

p1 = ggplot() +
  geom_bar(data = select(p4,3,50:51), aes_string(x = Values, y = Cost.Properties, fill = 'Operating Strategy'), stat="identity", position="stack" )







library(plotly)
library(dplyr)
library(reshape2)

df <- structure(c(106487, 495681, 1597442, 2452577, 2065141, 2271925, 4735484, 3555352, 8056040, 4321887, 2463194, 347566, 621147, 1325727, 1123492, 800368, 761550, 1359737, 1073726, 36, 53, 141, 41538, 64759, 124160, 69942, 74862, 323543, 247236, 112059, 16595, 37028, 153249, 427642, 1588178, 2738157, 2795672, 2265696, 11951, 33424, 62469, 74720, 166607, 404044, 426967, 38972, 361888, 1143671, 1516716, 160037, 354804, 996944, 1716374, 1982735, 3615225, 4486806, 3037122, 17, 54, 55, 210, 312, 358, 857, 350, 7368, 8443, 6286, 1750, 7367, 14092, 28954, 80779, 176893, 354939, 446792, 33333, 69911, 53144, 29169, 18005, 11704, 13363, 18028, 46547, 14574, 8954, 2483, 14693, 25467, 25215, 41254, 46237, 98263, 185986), .Dim = c(19, 5), .Dimnames = list(c("1820-30", "1831-40", "1841-50", "1851-60", "1861-70", "1871-80", "1881-90", "1891-00", "1901-10", "1911-20", "1921-30", "1931-40", "1941-50", "1951-60", "1961-70", "1971-80", "1981-90", "1991-00", "2001-06"), c("Europe", "Asia", "Americas", "Africa", "Oceania")))
df.m <- melt(df)
df.m <- rename(df.m, Period = Var1, Region = Var2)

p <- ggplot(df.m, aes(x = Period, y = value/1e+06,fill = Region)) + ggtitle("Migration to the United States by Source Region (1820-2006), In Millions")
p <- p + geom_bar(stat = "identity", position = "stack")

p <- ggplotly(p)









p1 = ggplot() +
  geom_bar(data = gen.plot, aes_string(x = x_col, y = 'TWh', fill='Type'), stat="identity", position="stack" ) +
  scale_color_manual(name='', values=c("grey40"), labels=c("Load"))+
  scale_fill_manual('', values = gen.color, limits=rev(gen.order))+     
  labs(y="Generation (TWh)", x=NULL)+
  guides(color = guide_legend(order=1), fill = guide_legend(order=2))+
  theme(    legend.key =      element_rect(color="grey80", size = 0.8),
            legend.key.size = grid::unit(1.0, "lines"),
            legend.text =     element_text(size=text.plot),
            legend.title =    element_blank(),
            #                         text = element_text(family="Arial"),
            axis.text =       element_text(size=text.plot/1.2),
            # axis.text.x =   element_text(face=2),
            axis.title =      element_text(size=text.plot, face=2),
            axis.title.y =    element_text(vjust=1.2),
            panel.margin =    unit(1.5, "lines"))

# Add something for if load only ??
# Add error bar line for load if provided
if(!is.null(load.data)){
  p1 = p1 + geom_errorbar(data = tot.load, aes_string(x = x_col, y='TWh', ymin='TWh', ymax='TWh', color='variable'), 
                          size=0.45, linetype='longdash')
}