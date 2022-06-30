source("C:/code/external/functions/preprocessing/dictionary_file.R")

f <- c(list.files(paste0(path_lasi_folder,"/AllstatesUTs"),full.names = TRUE),
       list.files(paste0(path_lasi_folder,"/Metrocities"),full.names = TRUE))
f <- f[regexpr("\\.dta",f)>0]

map(f[2:14],
    function(file){
      print(file);
      name = str_extract(file,"[A-Za-z0-9\\_]+\\.dta") %>% str_replace(.,pattern="\\.dta",replacement="");
      haven::read_dta(file) %>% 
        dictionary_file(.,type="dta2",name)
      
    })
