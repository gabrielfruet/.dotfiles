function sd (){
    z $(find * -type d | fzf)
}

function wkf (){
    cd "$(workfolder)" 
}

function snkcsfile (){
    touch "$(snkcs $1).$2"
}

