class UPlayerSwapControllerDevInput : UHazeDevInputHandler
{
	default Name = n"Swap Controllers";
	default Category = n"Default";

	default AddKey(EKeys::Gamepad_RightShoulder);
	default AddKey(EKeys::E);

	FTimerHandle ArrowTimerHandle;
	AHazePlayerCharacter SwapArrowPlayer;
	float SwapArrowTime = 0.0;

	default DisplaySortOrder = -100;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerInputDevToggles::Controller::SendInputToBothPlayers.MakeVisible();
		PlayerInputDevToggles::Controller::SendInputToBothPlayers.BindOnChanged(this, n"OnToggleSendInputToBothPlayers");
		OnToggleSendInputToBothPlayers(PlayerInputDevToggles::Controller::SendInputToBothPlayers.IsEnabled());
	}

	UFUNCTION()
	void OnToggleSendInputToBothPlayers(bool bNewValue)
	{
		if (bNewValue)
			Console::SetConsoleVariableInt("Haze.SendAllInputToBothPlayers", 1);
		else
			Console::SetConsoleVariableInt("Haze.SendAllInputToBothPlayers", 0);
	}

	UFUNCTION(BlueprintOverride)
	bool CanBeTriggered()
	{
#if EDITOR
		// In editor controllers can always be swapped
		return true;
#else
		// In cooked we cannot swap controllers when playing in network
		return !Network::IsGameNetworked();
#endif
	}

	UFUNCTION(BlueprintOverride)
	void Trigger()
	{
		Lobby::GetLobby().Debug_SwapControllers();

		// When we swap controllers we also want to swap inverted settings
		if (PlayerOwner.HasControl())
		{
			SwapSettings(n"InvertSteeringMio", n"InvertSteeringZoe");
			SwapSettings(n"InvertCameraMio", n"InvertCameraZoe");
			SwapSettings(n"InvertCameraHorizontalMio", n"InvertCameraHorizontalZoe");
		}

		// Close the dev input overlay
		auto DevInput = UHazeDevInputComponent::Get(PlayerOwner);
		DevInput.CloseAndFlushInput();

#if EDITOR
		// If we're in single-screen network mode showing both control and remote for this player,
		// swap to showing the other player as well.
		if (PlayerOwner.HasControl())
		{
			int CurViewMode = Console::GetConsoleVariableInt("Haze.SingleScreenNetworkViewMode");
			if (Network::HasWorldControl())
			{
				if (CurViewMode == 4)
					Console::SetConsoleVariableInt("Haze.SingleScreenNetworkViewMode", 5);
			}
			else
			{
				if (CurViewMode == 5)
					Console::SetConsoleVariableInt("Haze.SingleScreenNetworkViewMode", 4);
			}
		}
#endif

		// Show an arrow above the player after swapping if we're the one swapping
		SwapArrowTime = Time::PlatformTimeSeconds;
		SwapArrowPlayer = PlayerOwner.OtherPlayer;

		ArrowTimerHandle.ClearTimerAndInvalidateHandle();
		ArrowTimerHandle = Timer::SetTimer(this, n"DrawArrow", 0.0001, true);
	}

	void SwapSettings(FName MioSetting, FName ZoeSetting)
	{
		FString MioValue;
		FString ZoeValue;

		GameSettings::GetGameSettingsValue(MioSetting, MioValue);
		GameSettings::GetGameSettingsValue(ZoeSetting, ZoeValue);

		GameSettings::SetGameSettingsValue(MioSetting, ZoeValue);
		GameSettings::SetGameSettingsValue(ZoeSetting, MioValue);
	}

	UFUNCTION()
	void DrawArrow()
	{
		const float ArrowDuration = 0.45;
		const float ArrowSize = 600.0;
		const float ArrowLength = 130.0;
		const float ArrowLineSize = 10.0;

		float ArrowTimer = Time::PlatformTimeSeconds - SwapArrowTime;

		if (ArrowTimer > ArrowDuration)
		{
			ArrowTimerHandle.ClearTimerAndInvalidateHandle();
			return;
		}

		FVector ArrowDirection = SwapArrowPlayer.MovementWorldUp;

		FVector HeadPosition = SwapArrowPlayer.Mesh.GetSocketLocation(n"Head");
		FVector ArrowPosition = HeadPosition + ArrowDirection * 30.0;

		float LateralSize = Math::Sqrt(ArrowSize);
		FVector LateralOffset = SwapArrowPlayer.ViewRotation.RightVector * LateralSize;
		FVector BackwardOffset = SwapArrowPlayer.ViewRotation.ForwardVector * 6.5;

		float ArrowAlpha = Math::Clamp(1.0 - (ArrowTimer / ArrowDuration), 0.0, 1.0);

		Debug::DrawDebugLine(
			ArrowPosition + BackwardOffset,
			ArrowPosition + ArrowDirection * (ArrowLength * ArrowAlpha + 22.0) + BackwardOffset,
			FLinearColor::Black,
			ArrowLineSize + 6.0,
			0,
		);

		Debug::DrawDebugLine(
			ArrowPosition + BackwardOffset,
			ArrowPosition + ArrowDirection * LateralSize + LateralOffset + BackwardOffset,
			FLinearColor::Black,
			ArrowLineSize + 6.0,
			0,
		);

		Debug::DrawDebugLine(
			ArrowPosition + BackwardOffset,
			ArrowPosition + ArrowDirection * LateralSize - LateralOffset + BackwardOffset,
			FLinearColor::Black,
			ArrowLineSize + 6.0,
			0,
		);

		Debug::DrawDebugLine(
			ArrowPosition,
			ArrowPosition + ArrowDirection * (ArrowLength * ArrowAlpha + 20.0),
			SwapArrowPlayer.GetPlayerDebugColor(),
			ArrowLineSize,
			0,
		);

		Debug::DrawDebugLine(
			ArrowPosition,
			ArrowPosition + ArrowDirection * LateralSize + LateralOffset,
			SwapArrowPlayer.GetPlayerDebugColor(),
			ArrowLineSize,
			0,
		);

		Debug::DrawDebugLine(
			ArrowPosition,
			ArrowPosition + ArrowDirection * LateralSize - LateralOffset,
			SwapArrowPlayer.GetPlayerDebugColor(),
			ArrowLineSize,
			0,
		);
	}
}