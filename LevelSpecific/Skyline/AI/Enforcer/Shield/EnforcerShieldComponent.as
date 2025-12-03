event void FEnforcerShieldDisableSignature();
event void FEnforcerShieldResetSignature();

class UEnforcerShieldComponent : USceneComponent
{
	// TODO: Make the shield an actor instead?
	UPROPERTY(EditAnywhere)
	TSubclassOf<AHazeActor> ShieldClass;
	AHazeActor Shield;
	AHazeCharacter Character;

	bool bEnabled = true;
	int ShieldCounter;

	UBasicAIHealthComponent HealthComp;
	UHazeActorRespawnableComponent RespawnComp;

	UPROPERTY(Category = "Response", Meta = (BPCannotCallEvent))
	FEnforcerShieldDisableSignature OnDisableShield;

	UPROPERTY(Category = "Response", Meta = (BPCannotCallEvent))
	FEnforcerShieldResetSignature OnResetShield;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SpawnShield();		
		Character = Cast<AHazeCharacter>(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);		
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
	}

	private void SpawnShield()
	{
		if(Shield != nullptr)
			return;

		Shield = SpawnActor(ShieldClass);
		Shield.MakeNetworked(this, ShieldCounter);
		Shield.AttachToComponent(this);
		Shield.SetActorLocation(WorldLocation + ForwardVector * 100.0);
		ShieldCounter++;
		UGravityWhipResponseComponent WhipResponse = UGravityWhipResponseComponent::Get(Shield);
		WhipResponse.OnGrabbed.AddUFunction(this, n"OnGrabbed");
	}

	UFUNCTION()
	private void OnGrabbed(UGravityWhipUserComponent UserComponent,
		UGravityWhipTargetComponent TargetComponent,
		TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		auto HazeUser = Cast<AHazeActor>(UserComponent.Owner);
		if (HazeUser == nullptr)
			return;

		DisableShield(HazeUser);
	}

	UFUNCTION()
	private void OnRespawn()
	{
		bEnabled = true;
		SpawnShield();
		OnResetShield.Broadcast();		
	}

	void DisableShield(AHazeActor Instigator)
	{
		bEnabled = false;
		UEnforcerEffectHandler::Trigger_OnBreakArmor(Character);
		HealthComp.TakeDamage(0.01, EDamageType::Explosion, Instigator);
		Shield.DetachRootComponentFromParent(true);
		Shield = nullptr;
		OnDisableShield.Broadcast();		
	}
}