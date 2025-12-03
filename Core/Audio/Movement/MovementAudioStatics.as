namespace MovementAudio
{
	namespace Player
	{
		const FName PLAYER_HAND_SLIDING_GROUP = n"Player_Hands";

		const FName HAND_SLIDING_START_TAG = n"Hand_Slide_Start";
		const FName HAND_SLIDING_STOP_TAG = n"Hand_Slide_Stop";
		const FName HAND_SLIDING_LOOP_TAG = n"Hand_Slide_Loop";

		const float MAX_HAND_SLIDE_VELO_SPEED = 450.0;

		const FName LeftArmswingSocketName = n"LeftHandAudioAttach";
		const FName RightArmswingSocketName = n"RightHandAudioAttach"; 

		const FName LeftHandTraceSocketName = n"LeftHandAudioTrace";
		const FName RightHandTraceSocketName = n"RightHandAudioTrace"; 

		const FName LeftFootBoneName = n"LeftFootAudioTrace";
		const FName RightFootBoneName = n"RightFootAudioTrace";

		const FName LeftFootToeBoneName = n"LeftFootToeAudioTrace";
		const FName RightFootToeBoneName = n"RightFootToeAudioTrace";

		bool CanPerformFootsteps(UHazeMovementAudioComponent MoveAudioComp)
		{	
			return MoveAudioComp.CanPerformMovement(EMovementAudioFlags::Footsteps);
		}

		bool CanPerformArmswing(UHazeMovementAudioComponent MoveAudioComp)
		{
			return MoveAudioComp.CanPerformMovement(EMovementAudioFlags::Armswing);
		}

		bool CanPerformBreathing(UHazeMovementAudioComponent MoveAudioComp)
		{
			return MoveAudioComp.CanPerformMovement(EMovementAudioFlags::Breathing);
		}

		bool CanPerformEfforts(UHazeMovementAudioComponent MoveAudioComp)
		{
			return MoveAudioComp.CanPerformMovement(EMovementAudioFlags::Efforts);
		}

		FName GetMovementState(UHazeMovementAudioComponent MoveAudioComp, const FName& Group)
		{
			return MoveAudioComp.GetActiveMovementTag(Group);
		}
	}

	void RequestBlock(UObject Instigator, UHazeMovementAudioComponent MovementAudioComp, const EMovementAudioFlags InFlag)
	{
		MovementAudioComp.RequestBlockMovement(Instigator, InFlag);
	}

	void RequestUnBlock(UObject Instigator, UHazeMovementAudioComponent MovementAudioComp, const EMovementAudioFlags InFlag)
	{
		MovementAudioComp.RequestUnBlockMovement(Instigator, InFlag);
	}

	bool IsLeftHand(const EHandType& Hand)
	{
		return Hand == EHandType::Left;
	}

	namespace Dragons
	{
		const FName BackpackSpineSocketName = n"SpineAudioAttach";
		const FName SpineSocketName = n"SpineAudioAttach";

		const FName FrontLeftFootSocketName = n"FrontLeftFootAudioAttach";
		const FName FrontRightFootSocketName = n"FrontRightFootAudioAttach"; 

		const FName BackLeftFootTraceSocketName = n"BackLeftFootAudioTrace";
		const FName BackRightFootTraceSocketName = n"BackRightFootAudioTrace"; 

		const FName LeftWingSocketName = n"LeftWingAudioAttach";
		const FName RightWingSocketName = n"RightWingAudioAttach";
	}

	namespace TundraMonkey
	{
		const FName LeftFootSocketName = n"LeftFootAudioSocket";
		const FName RightFootSocketName = n"RightFootAudioSocket";

		const FName LeftHandSocketName = n"LeftHandAudioSocket";
		const FName RightHandSocketName = n"RightHandAudioSocket";

		const FName TailSocketName = n"TailAudioSocket";
	}

	namespace TundraTreeGuardian
	{
		const FName LeftFootSocketName = n"LeftFootAudioSocket";
		const FName RightFootSocketName = n"RightFootAudioSocket";
		const FName LeftHandSocketName = n"LeftHandAudioSocket";
		const FName RightHandSocketName = n"RightHandAudioSocket";

		const FName NeckSocketName = n"NeckAudioSocket";
		const FName HipSocketName = n"HipAudioSocket";
	}

	namespace FantasyOtter
	{
		const FName LeftFootSocketName = n"LeftFootAudioSocket";
		const FName RightFootSocketName = n"RightFootAudioSocket";
		const FName LeftHandSocketName = n"LeftHandAudioSocket";
		const FName RightHandSocketName = n"RightHandAudioSocket";

		const FName HeadSocketName = n"HeadAudioSocket";
		const FName TailSocketName = n"TailAudioSocket";
	}

	namespace TundraFairy
	{
		const FName LeftFootSocketName = n"LeftFootAudioSocket";
		const FName RightFootSocketName = n"RightFootAudioSocket";
	}

	namespace Pigs
	{
		const FName HeadSocketName = n"HeadAudio";
		const FName FrontLeftFootSocketName = n"LeftHandAudio";
		const FName FrontRightFootSocketName = n"RightHandAudio";
		const FName BackLeftFootSocketName = n"LeftFootAudio";
		const FName BackRightFootSocketName = n"RightFootAudio";
	}
}