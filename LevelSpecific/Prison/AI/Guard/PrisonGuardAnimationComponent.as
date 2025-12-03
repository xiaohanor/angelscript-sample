enum EPrisonGuardAnimationRequest
{
	TurnLeft45,
	TurnLeft90,
	TurnLeft135,
	TurnLeft180,
	TurnRight45,
	TurnRight90,
	TurnRight135,
	TurnRight180,
	Stop,
	Move,
	Attack,
	Stun,
	Restun,
}

// Let's try how this feels compared to the normal ai animation component tag system.
class UPrisonGuardAnimationComponent : UActorComponent
{
	EPrisonGuardAnimationRequest Request;
	UFeatureAnimInstancePrisonGuard AnimInstance;

	float MovementPlayRate = 1.2;
	FHazeAcceleratedFloat AccSpineYaw;

	bool HasActionRequest() const
	{
		if (Request > EPrisonGuardAnimationRequest::Move)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AnimInstance = Cast<UFeatureAnimInstancePrisonGuard>(Cast<AHazeCharacter>(Owner).Mesh.AnimInstance);
	}

	UAnimSequence GetAnimation(EPrisonGuardAnimationRequest AnimRequest)
	{
		switch (AnimRequest)
		{
			case EPrisonGuardAnimationRequest::Attack:
				return AnimInstance.AnimData.Attack.Sequence;
			case EPrisonGuardAnimationRequest::Stop:
				return AnimInstance.AnimData.MH.Sequence;
			case EPrisonGuardAnimationRequest::Move:
				return AnimInstance.AnimData.WalkStart.Sequence; // Not very useful...
			case EPrisonGuardAnimationRequest::Stun:
			case EPrisonGuardAnimationRequest::Restun:
				return AnimInstance.AnimData.StunnedEnter.Sequence;
			case EPrisonGuardAnimationRequest::TurnLeft45:
				return AnimInstance.AnimData.TurnLeft45.Sequence;
			case EPrisonGuardAnimationRequest::TurnLeft90:
				return AnimInstance.AnimData.TurnLeft90.Sequence;
			case EPrisonGuardAnimationRequest::TurnLeft135:
				return AnimInstance.AnimData.TurnLeft135.Sequence;
			case EPrisonGuardAnimationRequest::TurnLeft180:
				return AnimInstance.AnimData.TurnLeft180.Sequence;
			case EPrisonGuardAnimationRequest::TurnRight45:
				return AnimInstance.AnimData.TurnRight45.Sequence;
			case EPrisonGuardAnimationRequest::TurnRight90:
				return AnimInstance.AnimData.TurnRight90.Sequence;
			case EPrisonGuardAnimationRequest::TurnRight135:
				return AnimInstance.AnimData.TurnRight135.Sequence;
			case EPrisonGuardAnimationRequest::TurnRight180:
				return AnimInstance.AnimData.TurnRight180.Sequence;
		}
	}

	float GetRequestedAnimCurrentPosition(EPrisonGuardAnimationRequest AnimRequest)
	{
		UAnimSequence Anim = GetAnimation(AnimRequest);

		TArray<FHazePlayingAnimationData> Animations;
		AnimInstance.GetCurrentlyPlayingAnimations(Animations);
		for (FHazePlayingAnimationData AnimData : Animations)
		{
			if (Anim == AnimData.Sequence)
				return AnimData.CurrentPosition;
		}
		return 0.0;
	}

	float GetSpineYawTo(UHazeSkeletalMeshComponentBase Mesh, FVector FocusLocation, float MaxYaw)
	{
		FVector ToFocusLocal = Mesh.WorldTransform.InverseTransformVector(FocusLocation - Owner.ActorLocation);
		float ToFocusYaw = FRotator::NormalizeAxis(ToFocusLocal.Rotation().Yaw);
		return Math::Clamp(ToFocusYaw, -MaxYaw, MaxYaw);
	}
};
