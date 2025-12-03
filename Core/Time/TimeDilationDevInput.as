class UTimeDilationComponent : UActorComponent
{
	TArray<float> DilationValues;
	default DilationValues.Add(0.0001);
	default DilationValues.Add(0.01);
	default DilationValues.Add(0.05);
	default DilationValues.Add(0.1);
	default DilationValues.Add(0.25);
	default DilationValues.Add(0.5);
	default DilationValues.Add(1.0);
	default DilationValues.Add(2.0);
	default DilationValues.Add(4.0);
	default DilationValues.Add(8.0);
	default DilationValues.Add(16.0);
	int DilationIndex = 6;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
#if !RELEASE
		DevTogglesTimeDilation::ToggledTimeDilation.BindOnChanged(this, n"ToggleTime");
		SnapToToggle();
#endif
	}

#if !RELEASE
	UFUNCTION()
	private void ToggleTime(FName NewState)
	{
		SnapToToggle();
	}

	private void SnapToToggle()
	{
		int TargetIndex = 6;
		if (DevTogglesTimeDilation::Slowest.IsEnabled())
			TargetIndex = 0;
		if (DevTogglesTimeDilation::Half.IsEnabled())
			TargetIndex = 5;
		if (DevTogglesTimeDilation::One.IsEnabled())
			TargetIndex = 6;
		if (DevTogglesTimeDilation::Double.IsEnabled())
			TargetIndex = 7;
		if (DevTogglesTimeDilation::Fastest.IsEnabled())
			TargetIndex = DilationValues.Num() - 1;

		int Delta = TargetIndex - DilationIndex;
		ChangeTimeDilation(Delta);
	}
#endif

	void ChangeTimeDilation(int Delta)
	{
		DilationIndex = Math::Clamp(DilationIndex + Delta, 0, DilationValues.Num() - 1);
		Time::SetWorldDebugTimeDilation(DilationValues[DilationIndex]);

		SetComponentTickEnabled(!Math::IsNearlyEqual(DilationValues[DilationIndex], 1.0));
	}

	//Set the current timedilation to the lowest stored dilationvalue
	void ChangeToMinTimeDilation()
	{
		DilationIndex = 0;
		Time::SetWorldDebugTimeDilation(DilationValues[DilationIndex]);

		SetComponentTickEnabled(true);
	}

	//Set the current timedilation to the highest stored dilationvalue
	void ChangeToMaxTimeDilation()
	{
		DilationIndex = DilationValues.Num()-1;
		Time::SetWorldDebugTimeDilation(DilationValues[DilationIndex]);

		SetComponentTickEnabled(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		PrintToScreen("Debug Time Dilation: " + DilationValues[DilationIndex]);
	}
}

class UTimeDilationIncreaseDevInput : UHazeDevInputHandler
{
	default SetName(n"Faster Time Dilation");
	default SetCategory(n"Default");

	default AddKey(EKeys::Gamepad_FaceButton_Top);
	default AddKey(EKeys::Add);
	default AddKey(FKey(n"+"));

	default AddGlobalKey(EKeys::Add);

	default DisplaySortOrder = 90;

	UFUNCTION(BlueprintOverride)
	void Trigger()
	{
		auto DilationComp = UTimeDilationComponent::GetOrCreate(Game::Mio);
		DilationComp.ChangeTimeDilation(1);
	}

	UFUNCTION(BlueprintOverride)
	void GetStatus(FString& OutDescription, FLinearColor& OutColor)
	{
		float GameSpeed = Time::GetWorldTimeDilation();
		if (GameSpeed > 1.0)
		{
			OutColor = FLinearColor::Green;
			OutDescription = f"[ {GameSpeed :.0f}x ]";
		}
	}
}

class UTimeDilationDecreaseDevInput : UHazeDevInputHandler
{
	default SetName(n"Slower Time Dilation");
	default SetCategory(n"Default");

	default AddKey(EKeys::Gamepad_FaceButton_Bottom);
	default AddKey(EKeys::Subtract);
	default AddKey(EKeys::Hyphen);

	default AddGlobalKey(EKeys::Subtract);

	default DisplaySortOrder = 91;

	UFUNCTION(BlueprintOverride)
	void Trigger()
	{
		auto DilationComp = UTimeDilationComponent::GetOrCreate(Game::Mio);
		DilationComp.ChangeTimeDilation(-1);
	}

	UFUNCTION(BlueprintOverride)
	void GetStatus(FString& OutDescription, FLinearColor& OutColor)
	{
		float GameSpeed = Time::GetWorldTimeDilation();
		if (GameSpeed < 1.0)
		{
			OutColor = FLinearColor::Red;
			OutDescription = f"[ {GameSpeed}x ]";
		}
	}
}