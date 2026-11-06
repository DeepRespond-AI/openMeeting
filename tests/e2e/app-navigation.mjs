/** Internal compatibility routes have no public navigation entry. Keep the
 * existing native workbench tests within the mounted app/meeting session. */
export async function navigateWithinApp(page, href) {
  await page.evaluate(href => {
    const element=[...document.querySelectorAll('*')].find(el=>Object.keys(el).some(k=>k.startsWith('__reactFiber')));
    if(!element)throw Error('React app is not mounted');
    let fiber=element[Object.keys(element).find(k=>k.startsWith('__reactFiber'))];
    while(fiber.return)fiber=fiber.return;
    const queue=[fiber],seen=new Set();
    while(queue.length){
      const f=queue.pop();if(!f||seen.has(f))continue;seen.add(f);
      const router=f.memoizedProps?.value;
      if(router&&['push','replace','refresh','prefetch'].every(k=>typeof router[k]==='function')){router.push(href);return;}
      queue.push(f.child,f.sibling);
    }
    throw Error('Next app router not found');
  },href);
  await page.waitForURL(url=>url.pathname+url.search===href);
}
