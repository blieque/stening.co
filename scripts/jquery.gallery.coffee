---
---

# pseudo-globals
el = {} # element object
projectData = {}
siteData = []
columns = 4
lastOpenedProject = null
galleryHeight = 0
galleryIsOpen = true # kinda not true
emailOverlayIsOpen = false
commandSupportChecked = false

getColumns = ->

    columnsString = el.cssToJs.css 'z-index'
    columnsInt = parseInt columnsString
    if !isNaN(columnsInt) and # if there's a change, and it's valid
       columnsInt > 0 and
       columnsInt < 5 and
       columnsInt != columns
        columns = columnsInt
        do positionGalleryElement
        if galleryIsOpen
            do scrollToGallery

updateGalleryHeight = ->

    galleryHeight = do el.gallery.height

emailClick = (event) ->

    do event.preventDefault
    do toggleEmailOverlay

emailContentsClick = (event) ->

    do event.preventDefault
    do event.stopPropagation

    do el.emailBox.select
    elClickedInput = $ this
    if elClickedInput.is el.emailButton
        copySuccessful = document.execCommand 'copy'
        if copySuccessful
            el.emailOverlay.addClass 'success'

toggleEmailOverlay = ->

    if !commandSupportChecked and
       !document.queryCommandSupported 'copy'
        commandSupportChecked = true
        do el.emailButton.remove
        el.emailOverlay.addClass 'legacy'

    if emailOverlayIsOpen
        el.emailOverlay.css 'opacity', 0
        setTimeout ->
            el.emailOverlay.css 'display', 'none'
            el.emailOverlay.removeClass 'success'
        , 400
    else
        el.emailOverlay.css 'display', 'block'
        # don't ask
        setTimeout ->
            el.emailOverlay.css 'opacity', 1
        , 0
        do el.emailBox.select

    emailOverlayIsOpen = !emailOverlayIsOpen

previewClick = (event) ->

    do event.preventDefault

    elPreview = $ this
    projectIsOpen = elPreview.hasClass 'open'

    # remove the 'open' class from the last clicked preview
    $ '.open'
        .removeClass 'open'
        .addClass 'delay-transition'

    # becuase jquery's .delay() is bork
    setTimeout ->
        $ '.delay-transition'
            .removeClass 'delay-transition'
    , 600

    # user has clicked the preview for a project that is not already open
    if !projectIsOpen

        # change appearance of and locate clicked preview
        elPreview.addClass 'open'
        projectIndex = el.previews.index elPreview
        positionGalleryElement projectIndex

        # change images and text of the project
        changeGalleryProject projectIndex

    do toggleGallery

    if !projectIsOpen
        do scrollToGallery

scrollToGallery = ->

    # scroll to the gallery
    gapAboveGallery = (el.window.height() - galleryHeight) / 2
    gapAboveGallery = Math.max 0, gapAboveGallery
    $ 'body,html'
        .animate
            scrollTop: el.gallery.offset().top - gapAboveGallery
        , 400

positionGalleryElement = (projectIndex) ->

    if projectIndex == undefined or projectIndex == null
        projectIndex = el.previews.index $ '.open'

    # move the gallery into place in the dom
    if projectIndex >= 0
        lastOnRow = projectIndex + columns
        lastOnRow -= lastOnRow % columns
        lastOnRow = Math.min lastOnRow, el.previews.length
        el.gallery.insertAfter el.previews[lastOnRow - 1]

changeGalleryProject = (projectIndex) ->

    projectId = projectIndex + 1

    # find the selected project's data object
    if siteData.projects[projectIndex].id == projectId
        projectData = siteData.projects[projectIndex]
    else
        siteData.projects.forEach (project) ->
            if project.id == projectId
                projectData = project

    # remove/add image and thumbnail elements as needed
    requiredChange = projectData.galleryCount - el.conveyor.children().length
    removeOrAdd = null

    if requiredChange > 0
        removeOrAdd = ->
            el.templateImage.clone().appendTo el.conveyor
            el.templateThumbnail.clone(true).appendTo el.nav
    else if requiredChange < 0
        removeOrAdd = ->
            el.conveyor.children().last().remove()
            el.nav.children().last().remove()

    for i in [0...Math.abs requiredChange]
        do removeOrAdd

    # change element attributes (href, src) for the new project
    for i in [0...projectData.galleryCount]

        # function to return interpolated urls with scheme, domain, etc.
        imageUrl = (parts) ->
            # zero-pad numbers
            parts[1] = "00#{parts[1]}".slice -2
            parts[2] = "00#{parts[2]}".slice -2

            if parts[0] == ''
                # return anchor href if no image category is given
                "#{siteData.hrefPrefix}/#{parts[1]}.#{parts[2]}"
            else
                # return normal interpolated string
                "#{siteData.hrefPrefix}/images/#{parts[0]}/" +
                "#{parts[1]}.#{parts[2]}.png"

        # actually change the src and href attributes
        el.conveyor.children().eq(i)
            .attr 'src', imageUrl ['full', projectData.id, i + 1]
        el.nav.children().eq(i)
            .attr 'href', imageUrl ['', projectData.id, i + 1]
            .children().attr 'src', imageUrl ['thumb', projectData.id, i + 1]

    # change element content for the new project
    el.gallery.find 'h2'
        .text projectData.title

    # remove/add image and thumbnail elements as needed
    requiredChange = projectData.galleryCount - el.conveyor.children().length
    removeOrAdd = null

    if requiredChange > 0
        removeOrAdd = ->
            el.article.append document.createElement 'p'
    else if requiredChange < 0
        removeOrAdd = ->
            el.article.children('p').last().remove()

    for i in [0...Math.abs requiredChange]
        do removeOrAdd

    el.article = el.gallery.find 'article'
    for i in [0...projectData.galleryCount]
        el.article.children('p').eq(i).text projectData.descriptionFull[i]

    # scroll back to the first image unless we're reopening the same project
    if projectId != lastOpenedProject
        slideToImage 0

    lastOpenedProject = projectId

toggleGallery = (time) ->

    elPreviewOpen = $ '.open'
    galleryIsOpening = elPreviewOpen.length > 0

    if time == undefined or time == null
        time = 400

    if galleryIsOpening
        # open the gallery
        el.gallery.slideDown time, ->
            el.gallery.removeClass 'transition'
    else
        # update gallery height variable
        do updateGalleryHeight

        # close the gallery
        el.gallery.addClass 'transition'
        setTimeout ->
            el.gallery.slideUp time
        , 200

    galleryIsOpen = !galleryIsOpen

thumbnailClick = (event) ->

    do event.preventDefault

    elThumbnail = $ this
    imageIsCurrent = elThumbnail.hasClass 'current'
    imageIndex = el.nav.children().index elThumbnail

    # user has clicked the thumbnail for an image that is not the current one
    if !imageIsCurrent
        slideToImage imageIndex

slideToImage = (imageIndex) ->

    imageIndex = Math.max imageIndex, 0
    imageIndex = Math.min imageIndex, projectData.galleryCount - 1

    # place the 'current' class on the right thumbnail
    $ '.current'
        .removeClass 'current'
    el.nav
        .children()
        .eq imageIndex
        .addClass 'current'

    if imageIndex == 0
        el.galleryPrev.addClass 'unavailable'
    else
        el.galleryPrev.removeClass 'unavailable'

    if imageIndex + 1 == projectData.galleryCount
        el.galleryNext.addClass 'unavailable'
    else
        el.galleryNext.removeClass 'unavailable'

    rightValue = "#{imageIndex * 100}%"
    el.conveyor.css 'right', rightValue

slideToImageRelative = (changeInIndex) ->

    elThumbnail = $ '.current'
    currentIndex = el.nav.children().index elThumbnail

    newIndex = currentIndex + changeInIndex
    newIndex = Math.max newIndex, 0
    newIndex = Math.min newIndex, projectData.galleryCount - 1

    slideToImage newIndex

$ ->

    # kick off async stuff right away
    $.ajax
        url: 'data.json'
        dataType: 'json'

        success: (data, textStatus, jqXHR) ->
            siteData = data

        error: (jqXHR, textStatus, errorThrown) ->
            alert 'Error occurred while fetching site-data. The website will ' +
                  'most likely not work fully.\n\nError: ' + textStatus

    # find elements in the dom
    el.window = $ window

    el.hide = $ '#hide'
    el.cssToJs = $ '#css-to-js'

    el.emailAnchor = $ 'header div:last-child > a'
    el.emailOverlay = $ '#email'
    el.emailBox = $ '#email [readonly]'
    el.emailButton = $ '#email [type="submit"]'

    el.gallery = $ '#gallery'
    el.galleryPrev = $ '.img-nav.l'
    el.galleryNext = $ '.img-nav.r'

    el.conveyor = $ '#conveyor > :last-child'
    el.nav = $ '#content > nav'
    el.previews = $ 'section > a'
    el.templateImage = el.hide.children 'img'
    el.templateThumbnail = el.hide.children 'a'

    # events and bindings
    el.window.resize getColumns

    el.emailAnchor.click emailClick
    el.emailBox.click emailContentsClick
    el.emailButton.click emailContentsClick
    el.emailOverlay.click toggleEmailOverlay

    el.previews.click previewClick
    el.templateThumbnail.click thumbnailClick
    el.galleryPrev.click ->
        slideToImageRelative -1
    el.galleryNext.click ->
        slideToImageRelative 1

    # initialisation things
    toggleGallery 0
    do updateGalleryHeight
    do getColumns