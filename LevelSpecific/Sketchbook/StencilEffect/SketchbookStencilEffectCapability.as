class USketchbookStencilEffect : UHazeCapability
{
	default CapabilityTags.Add(n"SketchbookStencilValue");

	// The capabillity that spawns the bow runs on input 100, and needs this to be set before to be able to copy stencil values
	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 50;

	AHazePlayerCharacter OwningPlayer;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		OwningPlayer = Cast<AHazePlayerCharacter>(Owner);
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
		const auto StencilEffectComp = USketchbookStencilEffectComponent::Get(Owner);

		StencilEffect::ApplyStencilEffect(Game::Mio.Mesh, OwningPlayer, StencilEffectComp.OutlineDataAssetMio, this, EInstigatePriority::High);
		StencilEffect::ApplyStencilEffect(Game::Zoe.Mesh, OwningPlayer, StencilEffectComp.OutlineDataAssetZoe, this, EInstigatePriority::High);

		// ApplyStencilEffect applies a "random" stencil value to the players, pass that stencil value along to the PP shader
		ASketchbookPostProcess PostProcess = Sketchbook::GetSketchbookPostProcess();
		if (PostProcess != nullptr)
		{
			for (auto Player : Game::Players)
				PostProcess.SetPlayerStencilValue(Player, Player.Mesh.CustomDepthStencilValue);

			int PenShadowStencilValue = 64;
			if (Game::Mio.Mesh.CustomDepthStencilValue == PenShadowStencilValue)
				++PenShadowStencilValue;
			if (Game::Zoe.Mesh.CustomDepthStencilValue == PenShadowStencilValue)
				++PenShadowStencilValue;

			ASketchbookPencil Pen = Sketchbook::GetPencil();
			if (Pen != nullptr)
			{
				Pen.SetShadowStencilValue(PenShadowStencilValue);
				PostProcess.SetPenShadowStencilValue(PenShadowStencilValue);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for (auto Player : Game::Players)
			StencilEffect::ClearStencilEffect(Player.Mesh, OwningPlayer, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};