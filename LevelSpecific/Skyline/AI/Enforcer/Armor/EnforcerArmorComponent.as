event void FEnforcerArmorDisableSignature();
event void FEnforcerArmorResetSignature();

class UEnforcerArmorComponent : UActorComponent
{
	AHazeCharacter Character;

	UBasicAIHealthComponent HealthComp;
	UHazeActorRespawnableComponent RespawnComp;

	UPROPERTY(EditAnywhere)
	USkeletalMesh ArmorlessMesh;
	private USkeletalMesh DefaultMesh;

	UPROPERTY(BlueprintReadOnly)
	bool bArmorEnabled;

	UPROPERTY(Category = "Response", Meta = (BPCannotCallEvent))
	FEnforcerArmorDisableSignature OnDisableArmor;

	UPROPERTY(Category = "Response", Meta = (BPCannotCallEvent))
	FEnforcerArmorResetSignature OnResetArmor;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Character = Cast<AHazeCharacter>(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);		
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
		
		bArmorEnabled = true;
		DefaultMesh = Character.Mesh.SkeletalMeshAsset;
	}

	UFUNCTION()
	private void OnRespawn()
	{
		bArmorEnabled = true;
		// Character.Mesh.SkeletalMesh = DefaultMesh;
		OnResetArmor.Broadcast();
	}

	void DisableArmor(AHazeActor Instigator)
	{
		bArmorEnabled = false;
		// Character.Mesh.SkeletalMesh = ArmorlessMesh;
		UEnforcerEffectHandler::Trigger_OnBreakArmor(Character);
		HealthComp.TakeDamage(0.01, EDamageType::Explosion, Instigator);
		OnDisableArmor.Broadcast();
	}
}