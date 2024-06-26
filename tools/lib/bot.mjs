/**
 *
 * @param {{botUrl: string,token:string, groupNumber:string,message:string}} param0
 * @returns
 */
export const sendMessageToQQGroup = async ({ botUrl, groupNumber, message }) => {
  const url = new URL(botUrl)
  url.searchParams.append("group_id", groupNumber)
  url.searchParams.append("message", message)
  const res = await fetch(url.toString(), {
    method: 'GET',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
  })

  if (res.ok) {
    const result = await res.json()
    return result
  } else {
    const result = await res.text()
    return result
  }
}
