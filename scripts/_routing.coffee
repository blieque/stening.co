baseUrl = location.origin + location.pathname.replace /[a-z0-9-]*$/, ''

slugify = (name) ->

    # This function is intended to almost implement the behaviour of the Jekyll
    # method `Utils#slugify'. It differs from the Jekyll-flavoured Liquid filter
    # in that it removes apostrophes and dots before really slugifying:
    #
    #   Liquid filter: "Didn't Work" -> "didn-t-work"
    #   This function: "Didn't Work" -> "didnt-work"

    # convert to lowercase
    name = do name.toLowerCase
    # remove characters that shouldn't create a hyphen at the next step
    name = name.replace /[.']/g, ''
    # replace sequences of non-alphanumeric characters with a hyphen
    name = name.replace /[\W_]+/g, '-'
    # remove leading and trailing hyphens left over
    name = name.replace /^-|-$/g, ''

slugifyTitles = ->

    previousSlugs = []

    siteData.projects.forEach (project) ->

        newSlug = slugify project.title
        previousSlugs.push newSlug

        # account for duplicate slugs
        slugCount = previousSlugs.reduce (count, slug) ->
            # add `true' (1) for each occurence in the array
            count + (slug == newSlug)
        , 0
        if slugCount > 1
            newSlug += '-' + slugCount

        project.slug = newSlug

findProject = (categoryName, slug) ->

    category = null
    indexInCategory = null

    idLookup = typeof categoryName == 'number'

    if idLookup
        siteData.projects.some (project, projectIndex) ->
            if project.id == categoryName # categoryName is actually the id
                category = project.category
                indexInCategory = byCategory[project.category].indexOf project
                true # stop the loop
    else
        if slug in categoryNames
            category = categoryNames.indexOf slug
        else
            el.categoryAnchors.each (anchorIndex, anchor) ->
                if $(anchor).attr('href') == categoryName
                    category = anchorIndex
            byCategory[category].some (project, projectIndex) ->
                if project.slug == slug
                    indexInCategory = projectIndex
                    true # stop the loop

    {category, indexInCategory}

openFromUrlWhenReady = do ->

    # This function will only perform its task the second time it is called. The
    # function requires two different async tasks to be complete in order to
    # work.

    calledBefore = false
    ->
        if calledBefore
            do openFromUrl
        calledBefore = true

openFromUrl = ->

    # url will not end in a slash, unless no project is specified in it
    path = location.pathname.split '/'
    categoryName = path[path.length - 2]
    slug = path[path.length - 1]

   # if slug != ''

    project = null
    if categoryName != ''
        project = findProject categoryName, slug
    else
        # no slug was given, but rather an id
        if !isNaN slugInt = parseInt slug
            project = findProject slugInt

    if project != undefined
        onceCategoryIsSet = ->
            if project.indexInCategory != null
                el.previews.eq(project.indexInCategory).click()

        if currentCategory != project.category
            el.categoryAnchors.eq(project.category).trigger 'click', [0]
            setTimeout onceCategoryIsSet, 0
        else
            onceCategoryIsSet()

changeWindowAddress = ->

    if siteData

        newHref = siteData.hrefPrefix + '/' + \
                  currentCategoryName
        if $('.open').length > 0
            newHref += '/' + projectData.slug
        if newHref != location.href
            history.replaceState {}, '', newHref