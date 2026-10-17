import base64
import unittest
from unittest.mock import MagicMock, patch

from bson import ObjectId
from fastapi import HTTPException

from api import post_robot_image
from models.robot_image import RobotImageUpload


def make_upload(image_bytes: bytes, content_type: str = "image/jpeg"):
    return RobotImageUpload(
        event="2026test",
        team=971,
        groupId="group-1",
        scoutInfo={
            "userId": "scout",
            "firstName": "Scout",
            "username": "scout",
            "team": "971",
        },
        content_type=content_type,
        image_base64=base64.b64encode(image_bytes).decode("ascii"),
    )


class RobotImageTests(unittest.TestCase):
    def test_capture_source_defaults_to_camera(self):
        self.assertEqual(
            make_upload(b"\xff\xd8\xffrobot").capture_source,
            "camera",
        )

    @patch("api.scout_info_is_current_group_member", return_value=True)
    @patch("api.rebuild_group_pit_status")
    @patch("api.RobotImagesCollection")
    def test_valid_jpeg_is_stored_in_separate_collection(
        self,
        collection,
        rebuild_status,
        _member_check,
    ):
        collection.insert_one.return_value = MagicMock(
            inserted_id=ObjectId("507f1f77bcf86cd799439011")
        )
        jpeg = b"\xff\xd8\xff" + b"robot-photo"

        result = post_robot_image(make_upload(jpeg))

        self.assertTrue(result["success"])
        stored = collection.insert_one.call_args.args[0]
        self.assertEqual(stored["image"], jpeg)
        self.assertEqual(stored["team"], 971)
        self.assertEqual(stored["group_id"], "group-1")
        rebuild_status.assert_called_once_with("group-1", "2026test")

    @patch("api.scout_info_is_current_group_member", return_value=True)
    def test_file_signature_must_match_content_type(self, _member_check):
        with self.assertRaises(HTTPException) as context:
            post_robot_image(make_upload(b"not-an-image"))

        self.assertEqual(context.exception.status_code, 400)


if __name__ == "__main__":
    unittest.main()
