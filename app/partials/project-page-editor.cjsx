React = require 'react'
AutoSave = require '../components/auto-save'
handleInputChange = require '../lib/handle-input-change'
apiClient = require '../api/client'
PromiseToSetState = require '../lib/promise-to-set-state'

module.exports = React.createClass
  displayName: 'ProjectPageEditor'

  getDefaultState: ->
    pageContent: null

  fetchOrCreate: ->
    new Promise (resolve, reject) =>
      @props.project.get('pages', url_key: @props.page)
        .then ([page]) =>
          if page?
            resolve(page)
          else
            params = project_pages: { url_key: @props.page, title: @props.pageTitle, language: @props.project.primary_language }
            apiClient.post(@props.project._getURL("pages"), params)
              .then ([page]) =>
                resolve(page)
              .catch (e) ->
                reject(e)
        .catch (e) ->
          reject(e)

  mixins: [PromiseToSetState]

  componentDidMount: ->
    @promiseToSetState pageContent: @fetchOrCreate()

  render: ->
    <p>
      {if @state.pending.pageContent?
         <div>Loading</div>
       else if @state.rejected.pageContent?
         <div>{@state.rejected.pageContent.toString()}</div>
       else if @state.pageContent?
         <AutoSave resource={@state.pageContent}>
           <span className="form-label">{@props.pageTitle}</span>
           <br />
           <textarea
             className="standard-input full"
             name="content"
             defaultValue={@state.pageContent.content}
             rows="20"
             onChange={handleInputChange.bind @state.pageContent} />
         </AutoSave>}
    </p>
