class UMioFullScreenComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	bool bUseZoeInput = false;

	bool bHasSetInput = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FHazeDevInputInfo Info;
		Info.Name = n"ToggleZoeInput";
		Info.Category = n"Default";
		Info.OnTriggered.BindUFunction(this, n"ToggleZoeInput");

		Info.AddKey(EKeys::T);
		Info.AddKey(EKeys::Gamepad_DPad_Right);

		// Registering for both players, making in show up in both of their menus
		for(auto Player : Game::Players)
			Player.RegisterDevInput(Info);
	}

	UFUNCTION(DevFunction)
	void ToggleZoeInput()
	{
		bUseZoeInput = !bUseZoeInput;

		if(bUseZoeInput)
			Print("MioFullscreen input now handled by Zoe's right stick");
		else
			Print("MioFullscreen input now handled by Mio's left stick");
	}
}

namespace MioFullScreen
{
	void SetupFullScreenInput()
	{
		#if EDITOR
		auto Comp = UMioFullScreenComponent::GetOrCreate(Game::GetMio());
		if(Comp.bUseZoeInput && !Comp.bHasSetInput)
		{
			CapabilityInput::LinkActorToPlayerInput(Game::GetMio(), Game::GetZoe());
			Comp.bHasSetInput = true;
		}
		else if(!Comp.bUseZoeInput && Comp.bHasSetInput)
		{
			CapabilityInput::LinkActorToPlayerInput(Game::GetMio(), Game::GetMio());
			Comp.bHasSetInput = false;
		}
		#endif
	}

	bool GetUseZoeInput()
	{
		#if EDITOR
		auto Comp = UMioFullScreenComponent::GetOrCreate(Game::GetMio());
		return Comp.bUseZoeInput;
		#else
		return false;
		#endif
	}

	FName GetStickInputName()
	{
		#if EDITOR
		auto Comp = UMioFullScreenComponent::GetOrCreate(Game::GetMio());
		if(Comp.bUseZoeInput)
			return AttributeVectorNames::RightStickRaw;
		else
			return AttributeVectorNames::LeftStickRaw;
		#else
		return AttributeVectorNames::LeftStickRaw;
		#endif
	}

	FVector2D GetStickInput(UHazePlayerCapability Capability)
	{
		SetupFullScreenInput();
		return Capability.GetAttributeVector2D(GetStickInputName());
	}
}