class USkylineHotwireUserCapability : UHazePlayerCapability
{
//	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASkylineHotwire Hotwire;
	USkylineHotwireUserComponent UserComp;

	ASkylineHotwireTool Tool;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Hotwire = TListedActors<ASkylineHotwire>().Single;
		UserComp = USkylineHotwireUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!IsValid(Hotwire))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!IsValid(Hotwire))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Owner.BlockCapabilities(CapabilityTags::Movement, this);
		Owner.BlockCapabilities(CapabilityTags::Visibility, this);
		Owner.BlockCapabilities(CapabilityTags::Collision, this);
		Owner.BlockCapabilities(CapabilityTags::GameplayAction, this);

		UserComp.Tool = UserComp.SpawnTool(Player, Hotwire);
		UserComp.Tool.OnConnect.AddUFunction(Hotwire, n"HandleToolConnect");
		UserComp.Tool.OnDisconnect.AddUFunction(Hotwire, n"HandleToolDisconnect");
		UserComp.Tool.AttachToActor(Hotwire);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(CapabilityTags::Movement, this);
		Owner.UnblockCapabilities(CapabilityTags::Visibility, this);
		Owner.UnblockCapabilities(CapabilityTags::Collision, this);
		Owner.UnblockCapabilities(CapabilityTags::GameplayAction, this);
	
		UserComp.Tool.OnConnect.Unbind(Hotwire, n"HandleToolConnect");
		UserComp.Tool.OnDisconnect.Unbind(Hotwire, n"HandleToolDisconnect");
		UserComp.Tool.DestroyActor();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	/*	
		FVector2D Input = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
//		UserComp.Input = Input;
//		UserComp.bIsActivated = IsActioning(ActionNames::PrimaryLevelAbility);
	
		Tool.AddActorLocalRotation(FRotator(-Input.Y * UserComp.ToolPitchSpeed * DeltaTime, 0.0, 0.0));
		Tool.AddActorLocalOffset(FVector::RightVector * Input.X * UserComp.ToolSideSpeed * DeltaTime);
	*/
	}
};