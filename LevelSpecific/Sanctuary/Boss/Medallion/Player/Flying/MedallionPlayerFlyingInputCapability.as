class UMedallionPlayerFlyingInputComponent : UActorComponent
{
	FVector2D Input;
	
	access DebugAccess = private, UMedallionPlayerFlyingInputCapability;
	access : DebugAccess FVector2D BrothersInputLeft;
	access : DebugAccess FVector2D BrothersInputRight;
};

class UMedallionPlayerFlyingInputCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(MedallionTags::MedallionTag);
	default CapabilityTags.Add(MedallionTags::MedallionCoopFlying);
	default TickGroup = EHazeTickGroup::Input;
	UMedallionPlayerFlyingInputComponent IntputComp;
	UMedallionPlayerFlyingInputComponent OtherPlayerIntputComp;
	UMedallionPlayerComponent MedallionComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		IntputComp = UMedallionPlayerFlyingInputComponent::GetOrCreate(Owner);
		OtherPlayerIntputComp = UMedallionPlayerFlyingInputComponent::GetOrCreate(Player.OtherPlayer);
		MedallionComp = UMedallionPlayerComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!HasControl())
			return false;
		if (!MedallionComp.IsMedallionCoopFlying())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MedallionComp.IsMedallionCoopFlying())
			return false;
		return true;
	}

	FVector2D GetInput()
	{
#if EDITOR
		if (SanctuaryMedallionHydraDevToggles::Players::FlyingBrothersControls.IsEnabled() && !Network::IsGameNetworked())
		{
			// use whichever has stick input
			if (Player.IsMio())
			{
				if (IntputComp.BrothersInputLeft.Size() > KINDA_SMALL_NUMBER)
					return IntputComp.BrothersInputLeft;
				else
					return OtherPlayerIntputComp.BrothersInputLeft;
			}
			if (Player.IsZoe())
			{
				if (IntputComp.BrothersInputRight.Size() > KINDA_SMALL_NUMBER)
					return IntputComp.BrothersInputRight;
				else
					return OtherPlayerIntputComp.BrothersInputRight;
			}
		}
#endif
		return GetAttributeVector2D(AttributeVectorNames::MovementRaw);
	}

	FVector2D ConvertStickInput(FVector2D StickInput)
	{
		return FVector2D(StickInput.Y, StickInput.X);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
#if EDITOR
		IntputComp.BrothersInputLeft = ConvertStickInput(GetAttributeVector2D(AttributeVectorNames::LeftStickRaw));
		IntputComp.BrothersInputRight = ConvertStickInput(GetAttributeVector2D(AttributeVectorNames::RightStickRaw));
#endif
		IntputComp.Input = GetInput();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		IntputComp.Input = FVector2D();
		IntputComp.BrothersInputLeft = FVector2D();
		IntputComp.BrothersInputRight = FVector2D();
	}
};