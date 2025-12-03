enum ETeenDragonAcidAimMode
{
	AlwaysOn,
	LeftTriggerMode,
	OffsetWhenShooting,
	MAX
}

class UPlayerAcidTeenDragonComponent : UPlayerTeenDragonComponent
{
	bool bIsFiringAcid = false;
	bool bWantToFlapWings = false;
 	bool bLoopWingFlaps = false;
	bool bNonOffsetAimCamera = false;
	bool bIsAimingAtTarget = false;

	ETeenDragonAcidAimMode AimMode = ETeenDragonAcidAimMode::OffsetWhenShooting;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FHazeDevInputInfo DevInput;

		DevInput.Name = n"Cycle Acid Dragon Aim Mode";
		DevInput.Category = n"Dragon";
		DevInput.OnTriggered.BindUFunction(this, n"HandleCycleAimMode");
		DevInput.AddKey(EKeys::L);
		DevInput.AddKey(EKeys::Gamepad_FaceButton_Left);

		Game::GetMio().RegisterDevInput(DevInput);
	}

	UFUNCTION(NotBlueprintCallable)
	private void HandleCycleAimMode()
	{
		int Value = int(AimMode);
		Value = (Value + 1) % int(ETeenDragonAcidAimMode::MAX);
		AimMode = ETeenDragonAcidAimMode(Value);

		Print(f"{AimMode}", 5.0);
	}

	ATeenDragon SpawnDragon(AHazePlayerCharacter Player, TSubclassOf<ATeenDragon> DragonType) override
	{
		ATeenDragon Dragon = Super::SpawnDragon(Player, DragonType);
		auto AcidSpray = UTeenDragonAcidSprayComponent::Get(Player);
		AcidSpray.OnDragonSpawn(Player, Dragon);
		return Dragon;
	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// Should this go somewhere else?
		if(TeenDragon != nullptr && TeenDragon.Mesh != nullptr && AnimationState.Get() == ETeenDragonAnimationState::Gliding)
		{
			float Velocity = GetOwner().GetActorVelocity().Size();
			TeenDragon.Mesh.SetScalarParameterValueOnMaterials(n"wingFlappingStrength", Math::Clamp((Velocity / 250) * TeenDragon.WingFlappingStrength, 0, 25));
		}
		else
		{
			TeenDragon.Mesh.SetScalarParameterValueOnMaterials(n"wingFlappingStrength", 0);
		}
	}
}