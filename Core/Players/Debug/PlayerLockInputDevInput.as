class UPlayerLockInputDevInput : UHazeDevInputHandler
{
	default Name = n"Lock Input";
	default Category = n"Default";
	default DisplaySortOrder = 150;
	default AddKey(EKeys::H);
	default AddKey(EKeys::Gamepad_LeftThumbstick);

	UFUNCTION(BlueprintOverride)
	void Trigger()
	{
		auto InputLock = UHazeDevInputLockComponent::Get(PlayerOwner);
		if (InputLock.IsInputLockedBy(this))
			InputLock.UnlockInput(this);
		else
			InputLock.LockInput(this);
	}

	UFUNCTION(BlueprintOverride)
	void GetStatus(FString& OutDescription, FLinearColor& OutColor)
	{
		auto InputLock = UHazeDevInputLockComponent::Get(PlayerOwner);
		if (InputLock.IsInputLockedBy(this))
		{
			OutDescription = "[ LOCKED ]";
			OutColor = FLinearColor(0.88, 0.28, 0.28);
		}
	}
}

class UPlayerGlobalLockInputDevInput : UHazeDevInputHandler
{
	default Name = n"Lock Input (Global)";
	default Category = n"Default";
	default AddGlobalKey(EKeys::H);

	UFUNCTION(BlueprintOverride)
	void Trigger()
	{
		for(auto Player : Game::Players)
		{
			auto InputLock = UHazeDevInputLockComponent::Get(Player);
			if (InputLock.IsInputLockedBy(World))
			{
				InputLock.UnlockInput(World);
				Input::ResetAllInput();
			}
			else
			{
				InputLock.LockInput(World);
			}
		}
	}
}