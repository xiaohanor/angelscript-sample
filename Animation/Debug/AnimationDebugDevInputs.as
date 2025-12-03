/**
 * Toggle player mesh variants (RealWorld, Fantasy, SciFi)
 */
class UAnimToggleCharacterWardrobeDevInput : UHazeDevInputHandler
{
	default Name = n"Toggle Mesh Variant";
	default Category = n"Animation";

	default AddKey(EKeys::Gamepad_FaceButton_Left);
	default AddKey(EKeys::Q);

	default DisplaySortOrder = 100;

	UFUNCTION(BlueprintOverride)
	void Trigger()
	{
#if Editor
		TArray<FName> Variants;
		Variants.Add(n"/Game/Core/Players/DA_PlayerVariant_RealWorld.DA_PlayerVariant_RealWorld");
		Variants.Add(n"/Game/Core/Players/DA_PlayerVariant_Fantasy.DA_PlayerVariant_Fantasy");
		Variants.Add(n"/Game/Core/Players/DA_PlayerVariant_Scifi.DA_PlayerVariant_Scifi");

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			auto PlayerVariantComp = UPlayerVariantComponent::Get(Player);

			bool bIsMio = Player == Game::GetMio();
			for (int i = 0; i < Variants.Num(); i++)
			{
				const auto Variant = Cast<UHazePlayerVariantAsset>(Editor::LoadAsset(Variants[i]));
				const auto VariantMesh = bIsMio ? Variant.MioSkeletalMesh : Variant.ZoeSkeletalMesh;
				if (VariantMesh.GetName() == Player.Mesh.SkeletalMeshAsset.GetName())
				{
					const int NewIndex = Math::WrapIndex(i + 1, 0, Variants.Num());
					auto NewVariant = Cast<UHazePlayerVariantAsset>(Editor::LoadAsset(Variants[NewIndex]));
					PlayerVariantComp.ApplyPlayerVariantOverride(NewVariant, this, EInstigatePriority::High);
					break;
				}
			}
		}

#endif
	}
}


class UAnimIncreaseMovemntSpeedDevInput : UHazeDevInputHandler
{
    default Name = n"Increase Max Movement Speed";
    default Category = n"Animation";

    default AddKey(EKeys::Gamepad_FaceButton_Top);
    default AddKey(EKeys::W);

    default DisplaySortOrder = 101;

    UFUNCTION(BlueprintOverride)
    void Trigger()
    {
        TArray<int> ToggleableSpeedSpeeds;

        const int DEFAULT_SPEED = 500;

        ToggleableSpeedSpeeds.Add(150);
        ToggleableSpeedSpeeds.Add(250);
        ToggleableSpeedSpeeds.Add(DEFAULT_SPEED);

        for (AHazePlayerCharacter Player : Game::GetPlayers())
        {
            auto StrafeComp = UPlayerStrafeComponent::GetOrCreate(Player);

            auto FloorMotionComp = UPlayerFloorMotionComponent::Get(Player);
            for (int i = 0; i < ToggleableSpeedSpeeds.Num(); i++)
            {
                if (StrafeComp.IsStrafeEnabled())
                {
                    auto StrafeSettings = UPlayerStrafeSettings::GetSettings(Player);
                    if (float(ToggleableSpeedSpeeds[i]) / DEFAULT_SPEED > StrafeSettings.StrafeMoveScale)
                    {
                        StrafeSettings.StrafeMoveScale = float(ToggleableSpeedSpeeds[i]) / DEFAULT_SPEED;
                        PrintToScreenScaled("Speed: " + ToggleableSpeedSpeeds[i] , 1, FLinearColor::Green, 3);
                        break;
                    }
                }
                else
                {
                    if (ToggleableSpeedSpeeds[i] > FloorMotionComp.Settings.MaximumSpeed)
                    {
                        FloorMotionComp.Settings.MaximumSpeed = ToggleableSpeedSpeeds[i];
                        PrintToScreenScaled("Speed: " + FloorMotionComp.Settings.MaximumSpeed, 1, FLinearColor::Green, 3);
                        break;
                    }
                }
            }

        }

    }
}


class UAnimDecreaseMovemntSpeedDevInput : UHazeDevInputHandler
{
    default Name = n"Decrease Max Movement Speed";
    default Category = n"Animation";

    default AddKey(EKeys::Gamepad_FaceButton_Bottom);
    default AddKey(EKeys::S);

    default DisplaySortOrder = 103;

    UFUNCTION(BlueprintOverride)
    void Trigger()
    {
        TArray<int> ToggleableSpeedSpeeds;

        const int DEFAULT_SPEED = 500;

        ToggleableSpeedSpeeds.Add(DEFAULT_SPEED);
        ToggleableSpeedSpeeds.Add(250);
        ToggleableSpeedSpeeds.Add(150);

        for (AHazePlayerCharacter Player : Game::GetPlayers())
        {
            auto StrafeComp = UPlayerStrafeComponent::GetOrCreate(Player);

            auto FloorMotionComp = UPlayerFloorMotionComponent::Get(Player);
            for (int i = 0; i < ToggleableSpeedSpeeds.Num(); i++)
            {
                if (StrafeComp.IsStrafeEnabled())
                {
                    auto StrafeSettings = UPlayerStrafeSettings::GetSettings(Player);
                    if (float(ToggleableSpeedSpeeds[i]) / DEFAULT_SPEED < StrafeSettings.StrafeMoveScale)
                    {
                        StrafeSettings.StrafeMoveScale = float(ToggleableSpeedSpeeds[i]) / DEFAULT_SPEED;
                        PrintToScreenScaled("Speed: " + ToggleableSpeedSpeeds[i], 1, FLinearColor::Green, 3);
                        break;
                    }
                }
                else
                {
                    if (ToggleableSpeedSpeeds[i] < FloorMotionComp.Settings.MaximumSpeed)
                    {
                        FloorMotionComp.Settings.MaximumSpeed = ToggleableSpeedSpeeds[i];
                        PrintToScreenScaled("Speed: " + FloorMotionComp.Settings.MaximumSpeed, 1, FLinearColor::Green, 3);
                        break;
                    }
                }
            }

        }

    }
}


class UAnimShowCapusleDevInput : UHazeDevInputHandler
{
	default Name = n"Toggle Capsule Visibility";
	default Category = n"Animation";

	default AddKey(EKeys::Gamepad_FaceButton_Right);
	default AddKey(EKeys::C);

	default DisplaySortOrder = 102;

	UFUNCTION(BlueprintOverride)
	void Trigger()
	{
		if(!HasControl())
			return;

		const FString DrawCapsuleConsoleCommand = "Haze.DrawDebugCapsule";
		
		const int CurrentValue = Console::GetConsoleVariableInt(DrawCapsuleConsoleCommand);
		const int NewValue = CurrentValue > 0 ? 0 : 1;
		Console::ExecuteConsoleCommand(f"{DrawCapsuleConsoleCommand} {NewValue}");
	}
}


class UAnimTogglePhysicalAnimDebugDevInput : UHazeDevInputHandler
{
	default Name = n"Toggle Physical Animation Debug";
	default Category = n"Animation";

	default AddKey(EKeys::Gamepad_DPad_Right);
	default AddKey(EKeys::P);

	default DisplaySortOrder = 104;

	UFUNCTION(BlueprintOverride)
	void Trigger()
	{
#if EDITOR
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			AActor CurrentActor = Player;
			for (int i = 0; i < 10; i++)
			{
				if (CurrentActor == nullptr)
					break;
				
				auto PhysicalAnimComp = UHazePhysicalAnimationComponent::GetOrCreate(CurrentActor);
				if (PhysicalAnimComp != nullptr)
				{
					const EHazePhysicalAnimationDebugState CurrentDebugState = PhysicalAnimComp.GetCurrentDebugState();
					EHazePhysicalAnimationDebugState NewState;
					switch (CurrentDebugState)
					{
						case EHazePhysicalAnimationDebugState::GhostAnimPose:
							NewState = EHazePhysicalAnimationDebugState::GhostPhysics;
							break;

						case EHazePhysicalAnimationDebugState::GhostPhysics:
							NewState = EHazePhysicalAnimationDebugState::NONE;
							break;

						default:
							NewState = EHazePhysicalAnimationDebugState::GhostAnimPose;
							break;
					}

					PhysicalAnimComp.SetCurrentDebugState(NewState);
				}

				CurrentActor = CurrentActor.AttachParentActor;
			}
			

		}
#endif
	}
}


class UAnimTogglePhysicalAnimEnableDebugDevInput : UHazeDevInputHandler
{
	default Name = n"Toggle Physical Animation Enabled";
	default Category = n"Animation";

	default AddKey(EKeys::Gamepad_DPad_Left);
	default AddKey(EKeys::O);

	default DisplaySortOrder = 104;

	UFUNCTION(BlueprintOverride)
	void Trigger()
	{
#if EDITOR
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			AActor CurrentActor = Player;
			for (int i = 0; i < 10; i++)
			{
				if (CurrentActor == nullptr)
					break;
				
				auto PhysicalAnimComp = UHazePhysicalAnimationComponent::Get(CurrentActor);
				if (PhysicalAnimComp != nullptr)
				{
					if (PhysicalAnimComp.GetCurrentDebugState() != EHazePhysicalAnimationDebugState::NoPhysics)
						PhysicalAnimComp.SetCurrentDebugState(EHazePhysicalAnimationDebugState::NoPhysics);
					else 
						PhysicalAnimComp.SetCurrentDebugState(EHazePhysicalAnimationDebugState::NONE);
				}

				CurrentActor = Player.AttachParentActor;
			}
		}
#endif
	}
}


class UAnimToggleFullscreenDebugDevInput : UHazeDevInputHandler
{
	default Name = n"Toggle Screen View Size";
	default Category = n"Animation";

	default AddKey(EKeys::Gamepad_DPad_Up);
	default AddKey(EKeys::F);

	default DisplaySortOrder = 105;

	UFUNCTION(BlueprintOverride)
	void Trigger()
	{
		for (auto Player : Game::GetPlayers())
		{
			auto FullScreenDebugComp = UAnimFullScreenDebugComponent::GetOrCreate(Player);
			if (Player == PlayerOwner)
			{
				FullScreenDebugComp.ToggleDebugViewSizeMode();
			}
			else 
			{
				FullScreenDebugComp.ClearViewSizeOverride();
			}
		}
	}
}

class UAnimToggleStrafeDevInput : UHazeDevInputHandler
{
    default Name = n"Toggle Strafe";
    default Category = n"Animation";

    default AddKey(EKeys::Gamepad_DPad_Down);
    default AddKey(EKeys::N);

    default DisplaySortOrder = 106;

    UFUNCTION(BlueprintOverride)
    void Trigger()
    {
        for (auto Player : Game::GetPlayers())
        {
            auto StrafeComp = UPlayerStrafeComponent::GetOrCreate(Player);
            StrafeComp.SetStrafeEnabled(this, !StrafeComp.IsStrafeEnabled());
        }
    }
}