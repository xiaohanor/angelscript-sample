class UGravityWhipGloryKillBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.AddBlock(EBasicBehaviourRequirement::Weapon);

	default CapabilityTags.Add(SkylineAICapabilityTags::GravityWhippable);

	UGravityWhipResponseComponent WhipResponse;
	UBasicAIHealthComponent HealthComp;
	UBasicAICharacterMovementComponent MoveComp;
	UGravityWhippableComponent WhippableComp;
	USkylineEnforcerSentencedComponent SentencedComp;
	UGravityWhippableSettings WhippableSettings;

	bool bHitGloryKillActive = false;
	FGravityWhipActiveGloryKill ActiveGloryKill;
	FVector StartLocation;
	FQuat StartRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		WhipResponse = UGravityWhipResponseComponent::Get(Owner);
		WhipResponse.OnGloryKill.AddUFunction(this, n"OnGloryKill");
		WhipResponse.OnGloryKillEnded.AddUFunction(this, n"OnGloryKillEnded");

		HealthComp = UBasicAIHealthComponent::Get(Owner);
		SentencedComp = USkylineEnforcerSentencedComponent::GetOrCreate(Owner);
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		WhippableComp = UGravityWhippableComponent::GetOrCreate(Owner);
		WhippableSettings = UGravityWhippableSettings::GetSettings(Owner);
	}

	UFUNCTION()
	private void OnGloryKill(UGravityWhipUserComponent UserComponent,
	                            FGravityWhipActiveGloryKill GloryKill)
	{
		bHitGloryKillActive = true;
		ActiveGloryKill = GloryKill;
		Owner.PlaySlotAnimation(Animation = ActiveGloryKill.Sequence.EnforcerAnimation.Sequence);
	}

	UFUNCTION()
	private void OnGloryKillEnded()
	{
		bHitGloryKillActive = false;
		Owner.StopAllSlotAnimations();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;

		if (bHitGloryKillActive)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;

		if (!bHitGloryKillActive)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		HealthComp.SetStunned();
		SentencedComp.Sentence();

		StartLocation = Owner.ActorLocation;
		StartRotation = Owner.ActorQuat;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		HealthComp.ClearStunned();
		Owner.ClearSettingsByInstigator(this);
		if(HasControl())
			CrumbEffects();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbEffects()
	{
		ForceFeedback::PlayWorldForceFeedback(ForceFeedback::Default_Light, Owner.ActorLocation, false, this, 150, 400);
		if(WhippableComp.ImpactCameraShake != nullptr)
		{
			for(AHazePlayerCharacter Player : Game::Players)
				Player.PlayWorldCameraShake(WhippableComp.ImpactCameraShake, this, Owner.ActorLocation, 150, 400);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveGloryKill.bMoveEnforcerToPoint)
		{
			FVector MoveRatio = ActiveGloryKill.Sequence.EnforcerAnimation.Sequence.GetMoveRatioAtTime(
				ActiveDuration, 
				ActiveGloryKill.Sequence.EnforcerAnimation.Sequence.PlayLength,
			);

			FVector Delta = ActiveGloryKill.EnforcerTargetPoint - StartLocation;
			FVector Position = StartLocation + Delta * Math::Abs(MoveRatio.X);
			Owner.SetActorLocation(Position);
		}
		else if (ActiveGloryKill.Sequence.bMoveEnemyToZoe)
		{
			FVector MoveRatio = ActiveGloryKill.Sequence.EnforcerAnimation.Sequence.GetMoveRatioAtTime(
				ActiveDuration, 
				ActiveGloryKill.Sequence.EnforcerAnimation.Sequence.PlayLength,
			);

			FVector Delta = Game::Zoe.ActorLocation - StartLocation;

			FVector Offset;
			Offset += Delta * Math::Abs(MoveRatio.X);

			FVector Position = StartLocation + Offset;

			FQuat Rotation = Math::QInterpConstantTo(
				Owner.ActorQuat,
				FQuat::MakeFromZX(StartRotation.UpVector, -Game::Zoe.ActorForwardVector),
				DeltaTime,
				PI,
			);
			Owner.SetActorLocationAndRotation(Position, Rotation);
		}
	}
}