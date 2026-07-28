import unittest

from api import app


class RouteRegistrationTests(unittest.TestCase):
    def test_extracted_routes_are_registered_once(self):
        application_routes = [
            (method, route.path)
            for route in app.routes
            for method in getattr(route, "methods", set())
            if method not in {"HEAD", "OPTIONS"}
            and route.path not in {
                "/docs",
                "/docs/oauth2-redirect",
                "/openapi.json",
                "/redoc",
            }
        ]
        expected_extracted_routes = {
            ("GET", "/"),
            ("GET", "/{event}/teams"),
            ("GET", "/{event}/{match}/teams"),
            ("GET", "/{event}/event/{team}/team"),
            ("GET", "/{event}/stats"),
            ("GET", "/groups/{group_id}/events/{event}/stats"),
            (
                "GET",
                "/groups/{group_id}/events/{event}/teams/{team}/stats",
            ),
            ("GET", "/{event}/predictions"),
            ("GET", "/searchkeys"),
            ("GET", "/cache/status"),
            ("GET", "/joincode/{group_id}"),
            ("GET", "/groups/{group_name}/invite"),
            ("POST", "/groups"),
            ("POST", "/groups/add-event"),
            ("POST", "/groups/remove-event"),
            ("GET", "/groups/{group_id}/events"),
            ("POST", "/groups/join"),
            ("POST", "/groups/join-request"),
            ("GET", "/groups/{group_id}/requests"),
            ("POST", "/groups/approve-request"),
            ("POST", "/groups/reject-request"),
            ("POST", "/groups/set-role"),
            ("GET", "/groups/{group_id}/members"),
            ("GET", "/user/group"),
        }

        self.assertTrue(
            expected_extracted_routes.issubset(set(application_routes))
        )
        self.assertEqual(len(application_routes), len(set(application_routes)))

    def test_openapi_schema_contains_every_application_path(self):
        schema = app.openapi()
        registered_paths = {
            route.path
            for route in app.routes
            if getattr(route, "include_in_schema", False)
        }

        self.assertEqual(set(schema["paths"]), registered_paths)


if __name__ == "__main__":
    unittest.main()
