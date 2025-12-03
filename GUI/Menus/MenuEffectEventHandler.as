struct FMainMenuButtonEventData
{
	UPROPERTY()
	UMainMenuButton Button;

	FMainMenuButtonEventData(UMainMenuButton InButton) 
	{
		Button = InButton;
	}
}

enum EMainMenuCameraTransitionType
{
	Fade,
	BlendTo,
	SnapTo,
}

struct FMainMenuCameraTransition
{
	UPROPERTY()
	EMainMenuCameraTransitionType Type;

	UPROPERTY()
	FMainMenuStateCameraInfo CameraInfo;

	FMainMenuCameraTransition(EMainMenuCameraTransitionType InType, const FMainMenuStateCameraInfo& InCameraInfo)
	{
		Type = InType;
		CameraInfo = InCameraInfo;
	}
}

struct FMainMenuStateChangeData
{
	UPROPERTY()
	UMainMenuStateWidget Widget;

	UPROPERTY()
	EMainMenuState State;

	FMainMenuStateChangeData(UMainMenuStateWidget InWidget, EMainMenuState InState)
	{
		Widget = InWidget;
		State = InState;
	}
}

struct FOptionsMenuSwitchToPageData
{
	UPROPERTY()
	UOptionsMenuPage Widget;

	UPROPERTY()
	int PageIndex;

	UPROPERTY()
	EFocusCause FocusCause;

	FOptionsMenuSwitchToPageData(UOptionsMenuPage InWidget, int InPageIndex, EFocusCause InFocusCause)
	{
		Widget = InWidget;
		PageIndex = InPageIndex;
		FocusCause = InFocusCause;
	}
}

struct FChapterSelectItemsRefreshData
{
	UPROPERTY()
	UChapterSelectWidget Widget;

	FChapterSelectItemsRefreshData(UChapterSelectWidget InWidget)
	{
		Widget = InWidget;
	}
}

struct FChapterSelectPlayerMeshData
{
	UPROPERTY()
	USkeletalMesh Active;

	UPROPERTY()
	float Duration;

	FChapterSelectPlayerMeshData(USkeletalMesh InActive, float InDuration)
	{
		Active = InActive;
		Duration = InDuration;
	}
}

struct FMessageDialogData
{
	UPROPERTY()
	UMessageDialogWidget Widget;

	FMessageDialogData(UMessageDialogWidget InWidget)
	{
		Widget = InWidget;
	}
}

struct FPauseMenuStateChangeData
{
	UPROPERTY()
	UPauseMenu Widget;

	UPROPERTY()
	EPauseMenuState State;

	FPauseMenuStateChangeData(UPauseMenu InWidget, EPauseMenuState InState)
	{
		Widget = InWidget;
		State = InState;
	}
}

struct FCharacterSelectedData
{
	UPROPERTY()
	EHazePlayer Player;

	UPROPERTY()
	bool bReady = false;

	UPROPERTY()
	bool bAlreadySelected = false;

	FCharacterSelectedData(EHazePlayer InPlayer, bool InbReady, bool InAlreadySelectedByOther)
	{
		Player = InPlayer;
		bReady = InbReady;
		bAlreadySelected = InAlreadySelectedByOther;
	}
}

struct FMenuActionData
{
	UPROPERTY()
	UHazeUserWidget Widget;

	UPROPERTY()
	bool bMouseInput = false;

	// Controller/Keyboard Action
	FMenuActionData(UHazeUserWidget InWidget)
	{
		Widget = InWidget;
	}

	// Most likely by mouse input
	FMenuActionData(UHazeUserWidget InWidget, bool InMouseInput)
	{
		Widget = InWidget;
		bMouseInput = InMouseInput;
	}
}

struct FBootMenuStateChangeData
{
	UPROPERTY()
	UInitialBootSequencePage Widget;

	FBootMenuStateChangeData(UInitialBootSequencePage InWidget)
	{
		Widget = InWidget;
	}
}

struct FTrialUpsellData
{
	UPROPERTY()
	UHazeUserWidget Widget;

	UPROPERTY()
	bool bAdded = false;

	FTrialUpsellData(UHazeUserWidget InWidget, bool InAdded)
	{
		Widget = InWidget;
		bAdded = InAdded;
	}
}

UCLASS(Abstract)
class UMenuEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCameraTransition(FMainMenuCameraTransition Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMenuStateChanged(FMainMenuStateChangeData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnOptionsSwitchToPage(FOptionsMenuSwitchToPageData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnChapterSelectItemsRefresh(FChapterSelectItemsRefreshData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnChapterSelectPlayerMesh(FChapterSelectPlayerMeshData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMessageDialog(FMessageDialogData DialogData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPauseMenuStateChanged(FPauseMenuStateChangeData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartGameInitiated() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCharacterSelected(FCharacterSelectedData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDefaultClick(FMenuActionData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDefaultHover(FMenuActionData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBootMenuChanged(FBootMenuStateChangeData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTrailUpsell(FTrialUpsellData Data) {}
};