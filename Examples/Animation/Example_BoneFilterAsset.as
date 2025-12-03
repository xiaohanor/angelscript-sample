
// All old Bone Filters as they were defined in C++

/*
case EHazeBoneFilterTemplate::BoneFilter_UpperBody:
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Spine", 0.33));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Spine1", 0.66));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Spine2", 1.0));
		break;
	case EHazeBoneFilterTemplate::BoneFilter_UpperBodyNoAttach:
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Spine", 0.33));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Spine1", 0.66));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Spine2", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftAttach", 0.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightAttach", 0.0));
		break;
	case EHazeBoneFilterTemplate::BoneFilter_UpperBodyNoForeArmsNoHead:
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Spine", 0.33));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Spine1", 0.66));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Spine2", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftForeArm", 0.5));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightForeArm", 0.5));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftHand", 0.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightHand", 0.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Neck", 0.33));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Head", 0.0));
		break;
	case EHazeBoneFilterTemplate::BoneFilter_UpperBodyNoAttachNoHead:
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Spine", 0.33));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Spine1", 0.66));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Spine2", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftAttach", 0.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightAttach", 0.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Neck", 0.33));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Head", 0.0));
		break;
	case EHazeBoneFilterTemplate::BoneFilter_UpperBodyHeavy:
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Spine", 0.15));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Spine1", 0.45));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Spine2", 0.85));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Neck", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Head", 0.6));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightShoulder", 0.75));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightArm", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftShoulder", 0.75));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftArm", 1.0));
		break;
	case EHazeBoneFilterTemplate::BoneFilter_UpperBodyTwoHandHvy:
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Spine", 0.05));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Spine1", 0.2));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Spine2", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Neck", 0.5));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Head", 0.0));
		break;
	case EHazeBoneFilterTemplate::BoneFilter_UpperBodyLeftHandHvy:
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Spine", 0.05));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Spine1", 0.2));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Spine2", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Neck", 0.5));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Head", 0.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightShoulder", 0.75));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightArm", 0.5));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightForeArm", 0.25));
		break;
	case EHazeBoneFilterTemplate::BoneFilter_UpperBodyLeftHandLight:
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Spine", 0.05));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Spine1", 0.2));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Spine2", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Neck", 0.5));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Head", 0.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightShoulder", 0.75));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightArm", 0.5));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightForeArm", 0.25));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftShoulder", 0.8));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftArm", 0.7));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftForeArm", 0.35));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftHand", 1.0));
		break;
	case EHazeBoneFilterTemplate::BoneFilter_UpperBodyRightHandHvy:
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Spine", 0.05));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Spine1", 0.2));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Spine2", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Neck", 0.5));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Head", 0.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftShoulder", 0.75));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftArm", 0.5));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftForeArm", 0.25));
		break;
	case EHazeBoneFilterTemplate::BoneFilter_UpperBodyRightHandLight:
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Spine", 0.05));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Spine1", 0.2));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Spine2", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Neck", 0.5));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Head", 0.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftShoulder", 0.75));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftArm", 0.5));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftForeArm", 0.25));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightShoulder", 0.8));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightArm", 0.7));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightForeArm", 0.35));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightHand", 1.0));
		break;
	case EHazeBoneFilterTemplate::BoneFilter_UpperBodyNoArms:
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Spine", 0.15));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Spine1", 0.45));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Spine2", 0.85));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Neck", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Head", 0.6));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightShoulder", 0.5));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightArm", 0.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftShoulder", 0.5));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftArm", 0.0));
		break;
	case EHazeBoneFilterTemplate::BoneFilter_UpperBodyNoHead:
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Spine", 0.33));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Spine1", 0.66));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Spine2", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Neck", 0.5));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Head", 0.0));
		break;
	case EHazeBoneFilterTemplate::BoneFilter_Spine:
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Spine", 1.0));
		break;
	case EHazeBoneFilterTemplate::BoneFilter_SpineNoAttach:
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Spine", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftAttach", 0.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightAttach", 0.0));
		break;
	case EHazeBoneFilterTemplate::BoneFilter_Shoulders:
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftShoulder", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightShoulder", 1.0));
		break;
	case EHazeBoneFilterTemplate::BoneFilter_LeftShoulder:
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftShoulder", 1.0));
		break;
	case EHazeBoneFilterTemplate::BoneFilter_RightShoulder:
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightShoulder", 1.0));
		break;
	case EHazeBoneFilterTemplate::BoneFilter_Arms:
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftArm", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightArm", 1.0));
		break;
	case EHazeBoneFilterTemplate::BoneFilter_LeftArm:
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftArm", 1.0));
		break;
	case EHazeBoneFilterTemplate::BoneFilter_RightArm:
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightArm", 1.0));
		break;
	case EHazeBoneFilterTemplate::BoneFilter_Hands:
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftHand", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightHand", 1.0));
		break;
	case EHazeBoneFilterTemplate::BoneFilter_LeftHand:
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftHand", 1.0));
		break;
	case EHazeBoneFilterTemplate::BoneFilter_RightHand:
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightHand", 1.0));
		break;
	case EHazeBoneFilterTemplate::BoneFilter_Fingers:
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftHandIndex1", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftHandThumb1", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftHandMiddle1", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftHandRing1", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftHandPinky1", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftAttach", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightHandIndex1", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightHandThumb1", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightHandMiddle1", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightHandRing1", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightHandPinky1", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightAttach", 1.0));
		break;
	case EHazeBoneFilterTemplate::BoneFilter_LeftFingers:
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftHandIndex1", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftHandThumb1", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftHandMiddle1", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftHandRing1", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftHandPinky1", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftAttach", 1.0));
		break;
	case EHazeBoneFilterTemplate::BoneFilter_LeftFingersNoAttach:
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftHandIndex1", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftHandThumb1", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftHandMiddle1", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftHandRing1", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftHandPinky1", 1.0));
		break;
	case EHazeBoneFilterTemplate::BoneFilter_LeftAttach:
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftAttach", 1.0));
		break;
	case EHazeBoneFilterTemplate::BoneFilter_RightFingers:
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightHandIndex1", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightHandThumb1", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightHandMiddle1", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightHandRing1", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightHandPinky1", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightAttach", 1.0));
		break;
	case EHazeBoneFilterTemplate::BoneFilter_RightFingersNoAttach:
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightHandIndex1", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightHandThumb1", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightHandMiddle1", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightHandRing1", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightHandPinky1", 1.0));
		break;
	case EHazeBoneFilterTemplate::BoneFilter_RightAttach:
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightAttach", 1.0));
		break;
	case EHazeBoneFilterTemplate::BoneFilter_Neck:
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Neck", 0.5));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Head", 1.0));
		break;
	case EHazeBoneFilterTemplate::BoneFilter_LeftEar:
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftEar", 1.0));
		break;
	case EHazeBoneFilterTemplate::BoneFilter_RightEar:
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightEar", 1.0));
		break;
	case EHazeBoneFilterTemplate::BoneFilter_Face:
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Jaw", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftEyeLidOutDown", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftEyeLidInDown", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftEyeLidInUp", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftEyeLidOutUp", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftEye", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftInnerBrow", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftMiddleBrow", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftOuterBrow", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("MiddleBrow", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftCornerLip", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftOuterUpperLip", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftMiddleUpperLip", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("UpperLip", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftSquint", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftNoseWrinkler", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftSquintInner", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftCheekUp", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftCheekMid", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftNasolabial", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftBuccinator", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftCheek", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftOrbicularisOuter", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftOrbicularisInner", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("NoseTip", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftNose", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftEar", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightEyeLidOutDown", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightEyeLidInDown", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightEyeLidInUp", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightEyeLidOutUp", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightEye", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightInnerBrow", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightMiddleBrow", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightOuterBrow", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightCornerLip", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightOuterUpperLip", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightMiddleUpperLip", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightSquint", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightNoseWrinkler", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightSquintInner", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightCheekUp", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightCheekMid", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightNasolabial", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightBuccinator", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightCheek", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightOrbicularisOuter", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightOrbicularisInner", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightNose", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightEar", 1.0));
		break;
	case EHazeBoneFilterTemplate::BoneFilter_LowerBody:
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Hips", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Spine", 0.0));
		break;
	case EHazeBoneFilterTemplate::BoneFilter_LowerBodyNoHips:
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Hips", 0.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftUpLeg", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightUpLeg", 1.0));
		break;
	case EHazeBoneFilterTemplate::BoneFilter_Hips:
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Hips", 1.0));
		break;
	case EHazeBoneFilterTemplate::BoneFilter_HipsNoAttach:
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Hips", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftAttach", 0.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightAttach", 0.0));
		break;
	case EHazeBoneFilterTemplate::BoneFilter_HipsOnly:
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Hips", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Spine", 0.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftUpLeg", 0.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightUpLeg", 0.0));
		break;
	case EHazeBoneFilterTemplate::BoneFilter_FullBody:
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Root", 1.0));
		break;
	case EHazeBoneFilterTemplate::BoneFilter_VehicleTrunk:
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Trunk", 1.0));
		break;
	case EHazeBoneFilterTemplate::BoneFilter_VehicleDoorLeftFront:
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Door_Left_Front", 1.0));
		break;
	case EHazeBoneFilterTemplate::BoneFilter_VehicleDoorRightFront:
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Door_Right_Front", 1.0));
		break;
	case EHazeBoneFilterTemplate::BoneFilter_VehicleDoorLeftBack:
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Door_Left_Back", 1.0));
		break;
	case EHazeBoneFilterTemplate::BoneFilter_VehicleDoorRightBack:
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Door_Right_Back", 1.0));
		break;
	case EHazeBoneFilterTemplate::BoneFilter_VehicleTrunkLeftBox:
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("FlaskContainer", 1.0));
		break;
	case EHazeBoneFilterTemplate::BoneFilter_VehicleTrunkRightBox:
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("ToolsContainer", 1.0));
		break;
	case EHazeBoneFilterTemplate::BoneFilter_VehicleTrunkFlap:
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("TrunkFlap", 1.0));
		break;
	case EHazeBoneFilterTemplate::BoneFilter_MostlyHead:
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Neck", 1.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftShoulder", 0.8));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftArm", 0.5));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("LeftForeArm", 0.0));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightShoulder", 0.8));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightArm", 0.5));
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("RightForeArm", 0.0));
		break;
	case EHazeBoneFilterTemplate::BoneFilter_Backpack:
		BoneFilters.Add(FHazeBoneFilterTemplateListEntry("Backpack", 1.0));
		break;
*/