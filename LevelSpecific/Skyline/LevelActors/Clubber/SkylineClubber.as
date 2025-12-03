class ASkylineClubber : ABasicAIGroundMovementCharacter
{
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineClubberCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicAIGroundMovementCapability");	
	default CapabilityComp.DefaultCapabilities.Add(n"BasicAIAnimationMovementCapability");

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent WhipResponse;
	default WhipResponse.GrabMode = EGravityWhipGrabMode::Sling;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Spine")
	UGravityWhipTargetComponent WhipTarget;

	UPROPERTY(DefaultComponent)
	UGravityWhipThrowResponseComponent ThrowResponseComp;
	default ThrowResponseComp.bNonThrowBlocking = true;

	UPROPERTY(DefaultComponent)
	UBasicAICharacterMovementComponent MoveComp;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem DieFX;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		HealthComp.OnDie.AddUFunction(this, n"OnDied");
		UGravityWhippableSettings::SetDeathType(this, EGravityWhippableDeathType::Impact, this);
		UGravityWhippableSettings::SetEnableThrownDamage(this, true, this);
	}

	UFUNCTION()
	private void OnDied(AHazeActor ActorBeingKilled)
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(DieFX, ActorLocation);
		DestroyActor();
	}
}