class AIslandStormdrainToxicShiftRespawnManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent Billboard;
	default Billboard.SetSpriteName("S_Player");

	UPROPERTY(DefaultComponent)
	UIslandStormdrainToxicShiftRespawnManagerVisualizerComponent VisualizerComp;

	AIslandStormdrainFloatingShieldedPlatform CurrentSelectedPlatform;
#endif

	UPROPERTY(EditInstanceOnly)
	bool bSharedRespawnPoints = false;

	TArray<AIslandStormdrainFloatingShieldedPlatform> Platforms;
	TPerPlayer<AIslandStormdrainFloatingShieldedPlatform> CurrentRespawnPlatform;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TListedActors<AIslandStormdrainFloatingShieldedPlatform> ListedPlatforms;
		Platforms = ListedPlatforms.Array;
		for(int i = 0; i < Platforms.Num(); i++)
		{
			if(Platforms[i].RespawnPoint == nullptr || !Platforms[i].bProtectsPlayers)
				continue;

			Platforms[i].OnPlayerEnterShields.AddUFunction(this, n"OnEnterPlatform");
		}
	}

	UFUNCTION()
	private void OnEnterPlatform(AIslandStormdrainFloatingShieldedPlatform Platform, AHazePlayerCharacter Player)
	{
		if(Platform.RespawnPointPriority == -1 || CurrentRespawnPlatform[Player] == nullptr || Platform.RespawnPointPriority >= CurrentRespawnPlatform[Player].RespawnPointPriority)
			SetCurrentRespawnPlatform(Platform, Player);
	}

	void SetCurrentRespawnPlatform(AIslandStormdrainFloatingShieldedPlatform NewPlatform, AHazePlayerCharacter Player)
	{
		if(CurrentRespawnPlatform[Player] == NewPlatform)
			return;
		
		if(bSharedRespawnPoints)
		{
			CurrentRespawnPlatform[0] = NewPlatform;
			CurrentRespawnPlatform[1] = NewPlatform;

			Player.SetStickyRespawnPoint(CurrentRespawnPlatform[Player].RespawnPoint);
			Player.OtherPlayer.SetStickyRespawnPoint(CurrentRespawnPlatform[Player.OtherPlayer].RespawnPoint);
		}
		else
		{
			CurrentRespawnPlatform[Player] = NewPlatform;
			Player.SetStickyRespawnPoint(CurrentRespawnPlatform[Player].RespawnPoint);
		}
	}
}

#if EDITOR
class UIslandStormdrainToxicShiftRespawnManagerVisualizerComponent : UActorComponent
{
	default bIsEditorOnly = true;
}

class UIslandStormdrainToxicShiftRespawnManagerVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UIslandStormdrainToxicShiftRespawnManagerVisualizerComponent;

	TArray<AIslandStormdrainFloatingShieldedPlatform> Platforms;
	AIslandStormdrainToxicShiftRespawnManager Manager;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		Manager = Cast<AIslandStormdrainToxicShiftRespawnManager>(Component.Owner);

		TListedActors<AIslandStormdrainFloatingShieldedPlatform> ShieldedPlatforms;
		Platforms = ShieldedPlatforms.Array;

		for(int i = 0; i < Platforms.Num(); i++)
		{
			AIslandStormdrainFloatingShieldedPlatform Platform = Platforms[i];

			if(Platform.RespawnPoint == nullptr)
				continue;

			if(!Platform.bProtectsPlayers)
				continue;

			FLinearColor Color = Manager.CurrentSelectedPlatform == Platform ? FLinearColor::Green : FLinearColor::Red;

			DrawLine(Manager.ActorLocation, Platform.RespawnPoint.ActorLocation, Color, 5.0);

			FVector StringLocation = Platform.RespawnPoint.GetStoredSpawnPosition(EHazePlayer::Mio).Location + FVector::UpVector * 50.0;
			SetHitProxy(FName(f"{i}"), EVisualizerCursor::Hand);
			DrawPoint(StringLocation, Color, 40.0);
			ClearHitProxy();
			DrawWorldString(f"{Platform.RespawnPointPriority}", StringLocation, Color, 1.5, -1.0, false, true);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool VisProxyHandleClick(FName HitProxy, FVector ClickOrigin, FVector ClickDirection, FKey Key, EInputEvent Event)
	{
		int Index = String::Conv_StringToInt(HitProxy.ToString());
		AIslandStormdrainFloatingShieldedPlatform Platform = Platforms[Index];
		
		if(Platform == Manager.CurrentSelectedPlatform)
		{
			Manager.CurrentSelectedPlatform = nullptr;
			return true;
		}

		Manager.CurrentSelectedPlatform = Platform;
		return true;
	}
}

class UIslandStormdrainToxicShiftRespawnManagerDetailsCustomization : UHazeScriptDetailCustomization
{
	default DetailClass = AIslandStormdrainToxicShiftRespawnManager;

	AIslandStormdrainToxicShiftRespawnManager Manager;
	UHazeImmediateDrawer Drawer;

	UFUNCTION(BlueprintOverride)
	void CustomizeDetails()
	{
		Manager = Cast<AIslandStormdrainToxicShiftRespawnManager>(GetCustomizedObject());

		// In BP (CDO does not have a world)
		if (GetCustomizedObject().World == nullptr)
			return;

		Drawer = AddImmediateRow(n"Respawn Point Priority");
		Manager.CurrentSelectedPlatform = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (GetCustomizedObject().World == nullptr)
			return;

		if (Manager == nullptr)
			return;

		if (!Drawer.IsVisible())
			return;

		auto Section = Drawer.Begin();
		if (ObjectsBeingCustomized.Num() > 1)
		{
			Section.Text("Multiple managers selected.").Color(FLinearColor::Gray).Bold();
			Drawer.End();
			return;
		}

		Section.Spacer(4);
		Section.Text("Please select a respawn point:").Color(FLinearColor::Gray).Bold();
		Section.Spacer(-2);

		TArray<AIslandStormdrainFloatingShieldedPlatform> Platforms;
		{
			TListedActors<AIslandStormdrainFloatingShieldedPlatform> ListedPlatforms;
			Platforms = ListedPlatforms.Array;
		}

		Platforms.Sort();
		for(int i = 0; i < Platforms.Num(); i++)
		{
			if(Platforms[i].RespawnPoint == nullptr)
				continue;

			if(!Platforms[i].bProtectsPlayers)
				continue;

			AIslandStormdrainFloatingShieldedPlatform Platform = Platforms[i];

			FHazeImmediateHorizontalBoxHandle Horizontal = Section.HorizontalBox().SlotFill();
			//Horizontal.VerticalBox().SlotHAlign(EHorizontalAlignment::HAlign_Left).Text(f"{i}:");
			FLinearColor ButtonBackgroundColor = Manager.CurrentSelectedPlatform == Platform ? FLinearColor(0.0, 0.2, 0.4, 1.0) : FLinearColor::Transparent;
			if(Horizontal.VerticalBox().SlotHAlign(EHorizontalAlignment::HAlign_Left).Button(f"{Platform.Name}").BackgroundColor(ButtonBackgroundColor).WasClicked())
			{
				Manager.CurrentSelectedPlatform = Manager.CurrentSelectedPlatform == Platform ? nullptr : Platform;
			}

			if(Manager.CurrentSelectedPlatform != Platform)
			{
				Horizontal.Spacer(4);
				Horizontal.VerticalBox().SlotHAlign(EHorizontalAlignment::HAlign_Right).Text(f"Priority: {Platform.RespawnPointPriority}");
				Horizontal.Spacer(10);
			}
			else
			{
				FHazeImmediateHorizontalBoxHandle EditHorizontal = Section.HorizontalBox();
				EditHorizontal.Text("Priority");
				EditHorizontal.Spacer(4);
				float Input = EditHorizontal.FloatInput().Tooltip("The respawn point priority for this respawn point").MinMax(-1, 100).Value(Manager.CurrentSelectedPlatform.RespawnPointPriority);
				int IntInput = Math::FloorToInt(Input);

				if(EditHorizontal.Button("-5").Tooltip("Remove 5 from the priority").WasClicked())
					IntInput -= 5;
				
				if(EditHorizontal.Button("-").Tooltip("Remove 1 from the priority").WasClicked())
					IntInput--;

				if(EditHorizontal.Button("+").Tooltip("Add 1 to the priority").WasClicked())
					IntInput++;

				if(EditHorizontal.Button("+5").Tooltip("Add 5 to the priority").WasClicked())
					IntInput += 5;
				
				IntInput = Math::Clamp(IntInput, -1, 100);
				if(IntInput != Manager.CurrentSelectedPlatform.RespawnPointPriority)
					GetCustomizedObject().World.MarkPackageDirty();

				Manager.CurrentSelectedPlatform.RespawnPointPriority = IntInput;

				Section.Spacer(4);
			}
		}

		Drawer.End();
	}
}
#endif