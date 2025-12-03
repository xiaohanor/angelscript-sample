/**
 * Transform the player into a split tooth
 */
class UDentistPlayerSplitToothCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 20;

	UDentistToothPlayerComponent ToothComp;
	UDentistToothSplitComponent ToothSplitComp;
	UDentistSplitToothComponent SplitToothComp;

	//ADentistSplitToothPlayer SplitTooth;

	ADentistTooth Tooth;
	USkeletalMesh ToothSkeletalMesh;
	TArray<UMaterialInterface> ToothMaterials;
	ADentistBoss Dentist;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player.ApplyDefaultSettings(DentistSplitToothPlayerSettings);

		ToothComp = UDentistToothPlayerComponent::Get(Player);
		ToothSplitComp = UDentistToothSplitComponent::Get(Player);
		SplitToothComp = UDentistSplitToothComponent::Get(Player);
		Dentist = TListedActors<ADentistBoss>().GetSingle();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!SplitToothComp.bIsSplit)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!SplitToothComp.bIsSplit)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Tooth = ToothComp.GetToothActor();
		ToothSkeletalMesh = Player.Mesh.SkeletalMeshAsset;
		ToothMaterials = Player.Mesh.Materials;

		Player.BlockCapabilities(Dentist::Tags::Dash, this);
		Player.BlockCapabilities(Dentist::Tags::GroundPound, this);
		Player.BlockCapabilities(Dentist::Tags::Jump, this);
		
		auto Mesh = ToothSplitComp.SplitToothPlayerMeshes[Player];
		Player.Mesh.SetSkeletalMeshAsset(Mesh);

		for(int i = 0; i < Mesh.Materials.Num(); i++)
			Player.Mesh.SetMaterial(i, Mesh.Materials[i].MaterialInterface);

		Player.CapsuleComponent.OverrideCapsuleSize(45, 100, this, bUpdateOverlaps = false);
		
		Tooth.RightEyeSpawner.GooglyEye.AddActorDisable(this);

		if(Dentist == nullptr)
			Dentist = TListedActors<ADentistBoss>().GetSingle();

		FDentistBossEffectHandlerOnPlayerToothSplitParams SplitParams;
		SplitParams.Player = Player;
		SplitParams.SplitToothAI = ToothSplitComp.GetSplitToothAI();
		UDentistBossEffectHandler::Trigger_OnPlayerToothSplit(Dentist, SplitParams);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(Dentist::Tags::Dash, this);
		Player.UnblockCapabilities(Dentist::Tags::GroundPound, this);
		Player.UnblockCapabilities(Dentist::Tags::Jump, this);

		Player.Mesh.SetSkeletalMeshAsset(ToothSkeletalMesh);

		for(int i = 0; i < ToothMaterials.Num(); i++)
			Player.Mesh.SetMaterial(i, ToothMaterials[i]);

		Player.CapsuleComponent.ClearCapsuleSizeOverride(this, false);

		Tooth.RightEyeSpawner.GooglyEye.RemoveActorDisable(this);

		if(Dentist == nullptr)
			Dentist = TListedActors<ADentistBoss>().GetSingle();

		FDentistBossEffectHandlerOnPlayerToothSplitParams SplitParams;
		SplitParams.Player = Player;
		SplitParams.SplitToothAI = ToothSplitComp.GetSplitToothAI();
		UDentistBossEffectHandler::Trigger_OnPlayerToothReunited(Dentist, SplitParams);
	}
};