struct FDentistBossToggleAttachmentToolActivationParams
{
	bool bAttach;
	EDentistBossTool ToolToToggle;
	USceneComponent ComponentToAttachTo;
	FName BoneName;
	EAttachmentRule AttachmentRule;
	EDetachmentRule DetachmentRule;
}

class UDentistBossToggleAttachmentToolCapability : UHazeActionQueueCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	FDentistBossToggleAttachmentToolActivationParams Params;

	ADentistBoss Dentist;
	UDentistBossSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = Cast<ADentistBoss>(Owner);
		
		Settings = UDentistBossSettings::GetSettings(Dentist);
	}
	
	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FDentistBossToggleAttachmentToolActivationParams InParams)
	{
		Params = InParams;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		auto Tool = Dentist.Tools[Params.ToolToToggle];

		if(Params.bAttach)
			Tool.AttachToComponent(Dentist.SkelMesh, Params.BoneName, Params.AttachmentRule);
		else
			Tool.DetachFromActor(Params.DetachmentRule);

		DetachFromActionQueue();			
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}
};