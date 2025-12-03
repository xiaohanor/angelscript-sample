namespace Centipede
{
	// No touching !!!!!!!!!!!!!!!!!!!!!!!!!!
		const float SegmentRadius = 50.0;
		const float MaxPlayerDistance = 1550.0;
	// No touching !!!!!!!!!!!!!!!!!!!!!!!!!!

	// How much can the centipede head twist relative to its neck
	const float MaxHeadAngle = 12.0;

	const float BodyGravityMagnitude = 980.0;

	// How much we'll fly over the target (if above)
	const float SwingJumpHeight = 200.0;

	// Distance from player-controlled bone to mandible interaction location
	const float PlayerMeshMandibleOffset = 200.0;

	float GetMaxPlayerDistanceSquared()
	{
		return Math::Square(MaxPlayerDistance);
	}

	const float MaxAirPlayerDistance = MaxPlayerDistance + SegmentRadius;

	const EHazePlayer HeadHazePlayer = EHazePlayer::Mio;
	const EHazePlayer TailHazePlayer = EHazePlayer::Zoe;

	AHazePlayerCharacter GetHeadPlayer()
	{
		return Game::GetPlayer(HeadHazePlayer);
	}

	AHazePlayerCharacter GetTailPlayer()
	{
		return Game::GetPlayer(TailHazePlayer);
	}

	const FVector WaterPlugTargetRelativeLoc = FVector(450, 0.0, 10);

	const float MaxPlayerSwingDistance = MaxPlayerDistance + PlayerMeshMandibleOffset + SegmentRadius;
}

class UCentipedeMovementSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Ground")
	float MoveSpeed = 900.0;

	UPROPERTY(Category = "Ground")
	float Acceleration = 20.0;

	UPROPERTY(Category = "Ground")
	float GroundRotationSpeed = 4.0;

	// Should always be false except for special cases
	UPROPERTY(Category = "Ground")
	bool bCanLeaveEdges = false;

	UPROPERTY(Category = "Ground")
	float StepUpSize = 100.0;

	UPROPERTY(Category = "Ground")
	float StepDownSize = 50.0;
}

class UCentipedeSwingMovementSettings : UHazeComposableSettings
{
	UPROPERTY()
	float MoveSpeed = 2800.0;

	// Degrees relative to WorldUp
	UPROPERTY()
	float MaxSwingAngle = 90.0;

	UPROPERTY()
	float JumpTimeDilation = 1.0;
}

class UPlayerCentipedeRideAnimationSettings : UDataAsset
{
	// Which bone to, uh... mount (Lol Eman you naughty dog)
	UPROPERTY()
	private FString MountBone = "Spine1";

	UPROPERTY()
	private ULocomotionFeatureCentipedeRiding MioLocomotionFeature;

	UPROPERTY()
	private ULocomotionFeatureCentipedeRiding ZoeLocomotionFeature;

	ULocomotionFeatureCentipedeRiding GetLocomotionFeatureForPlayer(EHazePlayer Player) const
	{
		return Player == EHazePlayer::Mio ? MioLocomotionFeature : ZoeLocomotionFeature;
	}

	FName GetMountBoneForPlayer(EHazePlayer Player) const
	{
		FString PlayerPrefix = Player == Centipede::HeadHazePlayer ? "Green" : "Blue";
		return FName(PlayerPrefix + MountBone);
	}
}