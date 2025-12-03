
UCLASS(Abstract)
class UWorld_Meltdown_SplitTraversal_Slide_Player_Hoverboard_Broom_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	FVector SplitOffset(500000.0, 0.0, 0.0);

	UPROPERTY(BlueprintReadOnly, NotVisible)
	ABattlefieldHoverboard Hoverboard;

	UFUNCTION(BlueprintEvent)
	void OnNewTrick(EBattlefieldHoverboardTrickType TrickType){}

	UFUNCTION(BlueprintEvent)
	void OnPlayerDied() {}

	UPROPERTY(EditInstanceOnly)
	ASplitTraversalPlayerCopy PlayerCopy;

	UPROPERTY(NotEditable)
	UHazeAudioEmitter HoverboardEmitter;

	UPROPERTY(NotEditable)
	UHazeAudioEmitter BroomEmitter;

	FVector CachedHoverboardLocation;
	const float MAX_BANKING_ANGLE = 10;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		UBattlefieldHoverboardComponent HoverboardComp = UBattlefieldHoverboardComponent::Get(PlayerOwner);
		Hoverboard = HoverboardComp.Hoverboard;

		HoverboardEmitter.AttachEmitterTo(Hoverboard.Mesh);
		BroomEmitter.AttachEmitterTo(PlayerCopy.Mesh);
	}

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		bUseAttach = false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(PlayerHealth::ArePlayersGameOver())
			return false;

		if(PlayerOwner.IsPlayerDead())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(PlayerHealth::ArePlayersGameOver())
			return true;

		if(PlayerOwner.IsPlayerDead())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UBattlefieldHoverboardTrickComponent TrickComp = UBattlefieldHoverboardTrickComponent::Get(PlayerOwner);
		TrickComp.OnNewTrick.AddUFunction(this, n"OnNewTrick");

		UPlayerHealthComponent::Get(PlayerOwner).OnStartDying.AddUFunction(this, n"OnPlayerDied");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UPlayerHealthComponent::Get(PlayerOwner).OnStartDying.UnbindObject(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		CachedHoverboardLocation = Hoverboard.Mesh.WorldLocation;
		const float PanningValue = GetPanningValue();

		HoverboardEmitter.SetRTPC(Audio::Rtpc_SpeakerPanning_LR, PanningValue, 0.0);
		BroomEmitter.SetRTPC(Audio::Rtpc_SpeakerPanning_LR, PanningValue, 0.0);
	}

	UFUNCTION(BlueprintPure)
	float GetBankingAlpha()
	{
		const FVector Velo = Hoverboard.Mesh.WorldLocation - CachedHoverboardLocation;
		const FVector Forward = Hoverboard.ActorForwardVector;
		return Velo.DotProduct(Forward);
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Is In SciFi"))
	bool IsInScifi() 
	{
		FVector2D ScreenPos;
		if(SceneView::ProjectWorldToScreenPosition(Game::Mio, PlayerOwner.ActorLocation, ScreenPos))
			return ScreenPos.X <= 0.5;
		
		return false;
	}

	private float GetPanningValue()
	{
		FVector PlayerPanningWorldLocation;
		float XAlpha = 0.0;

		if(PlayerOwner.IsMio())
		{
			PlayerPanningWorldLocation = PlayerOwner.ActorLocation;
			FVector2D ScreenPosition;
			if (!SceneView::ProjectWorldToViewpointRelativePosition(PlayerOwner, PlayerPanningWorldLocation, ScreenPosition))
				return 0.0;	

			XAlpha = ScreenPosition.X - 1;	
			float PanningValue = Math::GetMappedRangeValueClamped(FVector2D(-0.25, 0.25), FVector2D(-1.0, 1.0), XAlpha);
			PanningValue *= Audio::GetPanningRuleMultiplier();	
			return PanningValue;

		}
		else
		{

			PlayerPanningWorldLocation = PlayerCopy.ActorLocation;
			FVector2D ScreenPosition;
			if (!SceneView::ProjectWorldToViewpointRelativePosition(PlayerOwner, PlayerPanningWorldLocation, ScreenPosition))
				return 0.0;	

			XAlpha = ScreenPosition.X;
			float PanningValue = Math::GetMappedRangeValueClamped(FVector2D(-0.25, 0.25), FVector2D(-1.0, 1.0), XAlpha);
			PanningValue *= Audio::GetPanningRuleMultiplier();	
			return PanningValue;
		}			
	}
}