class UAcidActivatorMaterialCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AAcidActivator AcidActivator;
	UMaterialInstanceDynamic DynamicMaterial;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AcidActivator = Cast<AAcidActivator>(Owner); 
		DynamicMaterial = AcidActivator.ActivatorActor.MeshComp.CreateDynamicMaterialInstance(0);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		//Read from AcidActivator.AcidAlpha.Value 
	}
};