UCLASS(NotBlueprintable)
class UGravityBikeSplineJumpComponent : UActorComponent
{
	private AGravityBikeSpline GravityBike;
	private UGravityBikeSplineHoverComponent HoverComp;

	UGravityBikeSplineJumpSettings Settings;
	FInstigator JumpInstigator;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GravityBike = Cast<AGravityBikeSpline>(Owner);
		HoverComp = UGravityBikeSplineHoverComponent::Get(GravityBike);

		Settings = UGravityBikeSplineJumpSettings::GetSettings(GravityBike);
	}

	void StartJumping(FInstigator Instigator)
	{
		check(!IsJumping());

		if(HoverComp == nullptr)
			HoverComp = UGravityBikeSplineHoverComponent::Get(GravityBike);
		
		HoverComp.AddPitchImpulse(GravityBike.ActorRightVector * Settings.PitchImpulse);

		const FVector JumpDirection = GravityBike.ActorUpVector;

		FHazeTraceSettings TraceSettings = Trace::InitFromMovementComponent(GravityBike.MoveComp);
		TraceSettings.UseLine();
		FHitResult GroundHit = TraceSettings.QueryTraceSingle(GravityBike.ActorLocation, GravityBike.ActorLocation - JumpDirection * 100);

		FGravityBikeSplineJumpEventData EventData;

		if(GroundHit.IsValidBlockingHit())
		{
			EventData.bHasGroundImpact = true;
			EventData.GroundImpactPoint = GroundHit.ImpactPoint;
			EventData.GroundNormal = GroundHit.ImpactNormal;
		}

		UGravityBikeSplineEventHandler::Trigger_OnJump(GravityBike, EventData);

		GravityBike.AnimationData.JumpFrame = Time::FrameNumber;

		JumpInstigator = Instigator;
	}

	void StopJumping(FInstigator Instigator)
	{
		check(IsJumping());

		if(!ensure(JumpInstigator == Instigator))
			return;

		JumpInstigator = FInstigator();
	}

	bool IsJumping() const
	{
		return JumpInstigator.IsValid();
	}

	/**
	 * False if no impulse should be applied
	 */
	bool GetImpulseToApply(FVector&out ImpulseToApply)
	{
		const FVector JumpDirection = GravityBike.ActorUpVector;
		ImpulseToApply = JumpDirection * Settings.JumpImpulse;

		FVector TargetVelocity = GravityBike.ActorVelocity + ImpulseToApply;

		if(Settings.bLimitSplineUpVelocity)
		{
			FVector VerticalTargetVelocity = TargetVelocity.ProjectOnToNormal(GravityBike.GetSplineUp());
			const FVector HorizontalTargetVelocity = TargetVelocity - VerticalTargetVelocity;

			VerticalTargetVelocity = VerticalTargetVelocity.GetClampedToMaxSize(Settings.MaxSplineUpVelocity);
			TargetVelocity = HorizontalTargetVelocity + VerticalTargetVelocity;
		}

		if(Settings.bLimitJumpDirectionVelocity)
		{
			FVector JumpDirectionTargetVelocity = TargetVelocity.ProjectOnToNormal(JumpDirection);
			const FVector HorizontalTargetVelocity = TargetVelocity - JumpDirectionTargetVelocity;

			JumpDirectionTargetVelocity = JumpDirectionTargetVelocity.GetClampedToMaxSize(Settings.MaxJumpDirectionVelocity);
			TargetVelocity = HorizontalTargetVelocity + JumpDirectionTargetVelocity;
		}

		ImpulseToApply = TargetVelocity - GravityBike.ActorVelocity;

		if(!Settings.bAllowJumpImpulseBackwards && ImpulseToApply.DotProduct(GravityBike.ActorVelocity) < 0)
		{
			const FVector ImpulseAlongVelocity = ImpulseToApply.ProjectOnToNormal(GravityBike.ActorVelocity.GetSafeNormal());
			ImpulseToApply -= ImpulseAlongVelocity;
		}

		return !ImpulseToApply.IsNearlyZero();
	}
};