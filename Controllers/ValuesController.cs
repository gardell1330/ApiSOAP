using System.Web.Http;
using System.Web.Mvc;

namespace ApiSOAP.Controllers
{
    public class ValuesController : ApiController
    {
        // GET api/values
        public JsonResult Get()
        {
            var service = new BLZService.BLZService();
            var response = service.getBank("10020400");
            return new JsonResult()
            {
                Data = response,
                JsonRequestBehavior = JsonRequestBehavior.AllowGet
            };
        }

        // GET api/values/5
        public string Get(int id)
        {
            return "value" + id;
        }

        // POST api/values
        public void Post([FromBody]string value)
        {
        }

        // PUT api/values/5
        public void Put(int id, [FromBody]string value)
        {
        }

        // DELETE api/values/5
        public void Delete(int id)
        {
        }
    }
}
