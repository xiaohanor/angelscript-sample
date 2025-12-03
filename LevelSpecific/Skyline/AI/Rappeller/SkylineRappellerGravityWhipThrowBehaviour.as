// Rappeller will only take damage from impacts and will recover when slowing down
class USkylineRappellerGravityWhipThrowBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	default CapabilityTags.Add(SkylineAICapabilityTags::GravityWhippable);

	UGravityWhipResponseComponent WhipResponse;
	UBasicAIHealthComponent HealthComp;
	UBasicAICharacterMovementComponent MoveComp;
	UGravityWhippableSettings WhippableSettings;

	FVector ThrowImpulse = FVector::ZeroVector;
	AHazeActor ThrowingActor;
	float SlowedDuration;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		WhipResponse = UGravityWhipResponseComponent::Get(Owner);
		WhipResponse.OnThrown.AddUFunction(this, n"OnReleased");
		WhipResponse.OnThrown.AddUFunction(this, n"OnThrown");

		HealthComp = UBasicAIHealthComponent::Get(Owner);
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		WhippableSettings = UGravityWhippableSettings::GetSettings(Owner);
	}

	UFUNCTION()
	private void OnReleased(UGravityWhipUserComponent UserComponent,
		UGravityWhipTargetComponent TargetComponent,
		FHitResult HitResult, FVector Impulse)
	{
		ThrowImpulse = Impulse;
		ThrowingActor = Cast<AHazeActor>(UserComponent.Owner);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnThrown(UGravityWhipUserComponent UserComponent,
		UGravityWhipTargetComponent TargetComponent,
		FHitResult HitResult, FVector Impulse)
	{
		ThrowImpulse = Impulse;
		ThrowingActor = Cast<AHazeActor>(UserComponent.Owner);

		AHazeCharacter Character = Cast<AHazeCharacter>(Owner);
		Character.CapsuleComponent.SetCollisionProfileName(n"BlockAllDynamic");
		Character.CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::EnemyCharacter, ECollisionResponse::ECR_Block);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;

		if(ThrowImpulse == FVector::ZeroVector)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;

		// Always stop flailing about after a while
		if(ActiveDuration > WhippableSettings.MaxThrownDuration)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Owner.SetActorVelocity(ThrowImpulse * WhippableSettings.ThrownForceFactor);
		SlowedDuration = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		ThrowImpulse = FVector::ZeroVector;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.HasAnyValidBlockingContacts())
		{
			TArray<FHitResult> HitResults;
			if(MoveComp.HasWallContact())
				HitResults.Add(MoveComp.WallContact.ConvertToHitResult());

			if(MoveComp.HasGroundContact())
				HitResults.Add(MoveComp.GroundContact.ConvertToHitResult());
			
			if(MoveComp.HasCeilingContact())
				HitResults.Add(MoveComp.CeilingContact.ConvertToHitResult());

			for(auto HitResult : HitResults)
			{
				Damage::AITakeDamage(HitResult.Actor, WhippableSettings.ThrownDamage, Game::Zoe, WhippableSettings.ThrownDamageType);
			}

			// Ouch!
			float SpeedFactor = Math::Min(1.0, Owner.GetRawLastFrameTranslationVelocity().Size() * 0.001);
			HealthComp.TakeDamage(WhippableSettings.ThrownDamage * SpeedFactor, WhippableSettings.ThrownDamageType, ThrowingActor);
		}

		AnimComp.RequestFeature(LocomotionFeatureAISkylineTags::GravityWhippable, SubTagAIGravityWhippable::Thrown, EBasicBehaviourPriority::Medium, this);

		// Regain control when we've slowed down sufficiently
		if (Owner.GetActorVelocity().SizeSquared() < Math::Square(500.0))
			SlowedDuration += DeltaTime;
		else
			SlowedDuration = 0;
		if (SlowedDuration > 0.8)
			DeactivateBehaviour();
	}
}