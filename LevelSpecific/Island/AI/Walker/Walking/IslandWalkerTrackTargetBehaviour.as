
class UIslandWalkerTrackTargetBehaviour : UBasicBehaviour
{
	// Rotation only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;
	
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UIslandWalkerComponent WalkerComp;
	UIslandWalkerAnimationComponent WalkerAnimComp;
	UIslandWalkerSwivelComponent Swivel;
	UHazeSkeletalMeshComponentBase Mesh;
	UIslandWalkerSettings Settings;
	AHazePlayerCharacter PlayerTarget;

	FHazeAcceleratedFloat AccSwivelVelocity;
	float SwivelMinDistance;
	float TurnCooldown;
	float TurnEndTime;
	FRotator PrevRotation;
	float TurnLeftDuration;
	float TurnRightDuration;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		WalkerComp = UIslandWalkerComponent::Get(Owner);
		WalkerAnimComp = UIslandWalkerAnimationComponent::Get(Owner);
		Swivel = UIslandWalkerSwivelComponent::Get(Owner);
		Mesh = Cast<AHazeCharacter>(Owner).Mesh;
		Settings = UIslandWalkerSettings::GetSettings(Owner);
		TurnCooldown = 0.0; 
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!TargetComp.IsValidTarget(PlayerTarget))
			return true;
		if ((ActiveDuration > 2.0) && (ActiveDuration > TurnEndTime))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		PlayerTarget = Cast<AHazePlayerCharacter>(TargetComp.Target);
		AccSwivelVelocity.SnapTo(Swivel.SwivelVelocity);
		SwivelMinDistance = Swivel.WorldLocation.Dist2D(Owner.ActorLocation);
		TurnEndTime = 0.0;
		// Do not reset turn cooldown here
		PrevRotation = Owner.ActorRotation;

		TurnLeftDuration = WalkerAnimComp.GetFinalizedTotalDuration(FeatureTagWalker::Turn, SubTagWalkerTurn::Left45, Settings.TrackTargetTurnDuration);
		TurnRightDuration = WalkerAnimComp.GetFinalizedTotalDuration(FeatureTagWalker::Turn, SubTagWalkerTurn::Right45, Settings.TrackTargetTurnDuration);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		AnimComp.ClearFeature(this);	
		WalkerAnimComp.HeadAnim.ClearFeature(this);	
		WalkerComp.TrackTargetDuration = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (PlayerTarget == nullptr)
			return; // Deactivating some other behaviour removed target

		// We're tracking target
		WalkerComp.TrackTargetDuration = ActiveDuration;

		// Swivel to keep target in front of head
		FRotator SwivelRot = Mesh.GetSocketRotation(n"SpineBase");
		if (ShouldSwivel(SwivelRot))
			AccSwivelVelocity.AccelerateTo(GetSwivelTargetVelocity(SwivelRot), 4.0, DeltaTime);
		else
			AccSwivelVelocity.AccelerateTo(0.0, 3.0, DeltaTime);

		Swivel.Swivel(AccSwivelVelocity.Value);

		// Check if we should turn thorax as well
		if (ShouldStartTurning())
		{
			// Note that turns care about actor yaw, not swivel yaw
			float TurnDuration = TurnRightDuration;
			if (Owner.ActorRightVector.DotProduct(PlayerTarget.ActorLocation - Owner.ActorLocation) > 0.0)
			{
				TurnDuration = TurnRightDuration;
				AnimComp.RequestFeature(FeatureTagWalker::Turn, SubTagWalkerTurn::Right45, EBasicBehaviourPriority::Medium, this, TurnRightDuration);
				WalkerAnimComp.HeadAnim.RequestFeature(FeatureTagWalker::Turn, SubTagWalkerTurn::Right45, EBasicBehaviourPriority::Medium, this, TurnRightDuration);
			}
			else 
			{
				TurnDuration = TurnRightDuration;
				AnimComp.RequestFeature(FeatureTagWalker::Turn, SubTagWalkerTurn::Left45, EBasicBehaviourPriority::Medium, this, TurnLeftDuration);
				WalkerAnimComp.HeadAnim.RequestFeature(FeatureTagWalker::Turn, SubTagWalkerTurn::Left45, EBasicBehaviourPriority::Medium, this, TurnRightDuration);
			}
			TurnEndTime = ActiveDuration + TurnDuration;
			TurnCooldown = Time::GameTimeSeconds + Settings.TrackTargetTurnCooldown; // Use gametime so this carries over if deactivated then activated
		}
		if (ActiveDuration < TurnEndTime)
		{
			// Note that root motion will perform rotation, we do not need to use RotateTowards

			// Counter-adjust swivel
			Swivel.SwivelYaw -= (Owner.ActorRotation.Yaw - PrevRotation.Yaw);

			// Make sure turn anim isn't restarted
			if (ActiveDuration > TurnEndTime - 0.5)
				AnimComp.ClearFeature(this); 
		}
	
		if (ActiveDuration > Settings.SwitchTargetWhileTrackingDelay)
		{
			// We can switch target if other player is in front of us when current target isn't
			FVector OwnLoc = Owner.ActorLocation;
			FVector Forward = SwivelRot.ForwardVector;
			float TargetDot = Forward.DotProduct((PlayerTarget.ActorLocation - OwnLoc).GetSafeNormal());
			float CosA = 0.985;
			if ((TargetDot < CosA) && TargetComp.IsValidTarget(PlayerTarget.OtherPlayer) &&
				(Forward.DotProduct((PlayerTarget.OtherPlayer.ActorLocation - OwnLoc).GetSafeNormal()) > CosA))
			{
				TargetComp.Target = PlayerTarget.OtherPlayer;
				Cooldown.Set(0.5);
			} 
		}

		PrevRotation = Owner.ActorRotation;
	}

	bool ShouldSwivel(FRotator SwivelRot)
	{
		if (PlayerTarget.ActorLocation.IsWithinDist(Owner.ActorLocation, SwivelMinDistance))
			return false;
		FVector TargetDir = (PlayerTarget.ActorLocation - Swivel.WorldLocation).GetSafeNormal2D();
		if (SwivelRot.ForwardVector.DotProduct(TargetDir) > 0.99)
			return false;
		return true;	
	}

	float GetSwivelTargetVelocity(FRotator SwivelRot)
	{
		float Dir = 1.0;
		if (SwivelRot.RightVector.DotProduct(PlayerTarget.ActorLocation - Swivel.WorldLocation) < 0.0)
			Dir = -1.0;

		FVector2D CosAngleRange = FVector2D(0.95, 0.0);
		FVector2D SpeedRange = FVector2D(0.01, 1.0) * Settings.TrackTargetSwivelSpeed;
		float Speed = Math::GetMappedRangeValueClamped(CosAngleRange, SpeedRange, SwivelRot.ForwardVector.DotProduct((PlayerTarget.ActorLocation - Swivel.WorldLocation).GetSafeNormal2D()));
		return Speed * Dir;
	}

	bool ShouldStartTurning()
	{
		if (ActiveDuration < TurnEndTime)
			return false; // Already turning

		if (Time::GameTimeSeconds < TurnCooldown)
			return false; // Need to wait for cooldown

		FRotator TargetRot = (PlayerTarget.ActorLocation - Owner.ActorLocation).Rotation();
		if (Math::Abs(FRotator::NormalizeAxis(TargetRot.Yaw - Owner.ActorRotation.Yaw)) < Settings.TrackTargetTurnThresholdDegrees)
			return false; // Just swivel, no need to turn this little.

		return true;
	}
}
