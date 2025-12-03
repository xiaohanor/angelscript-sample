
UCLASS(Abstract)
class UWorld_Sketchbook_Shared_Interactable_Pencil_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnPencilLiftOffPaper(){}

	UFUNCTION(BlueprintEvent)
	void OnStartDrawingWord(FSketchbookPencilDrawWordParams DrawWordParams){}

	UFUNCTION(BlueprintEvent)
	void OnEraserLiftOffPaper(){}

	UFUNCTION(BlueprintEvent)
	void OnEraserTouchPaper(){}

	UFUNCTION(BlueprintEvent)
	void OnStartDrawingPropGroup(FSketchbookPencilDrawPropGroupParams DrawPropGroupParams){}

	UFUNCTION(BlueprintEvent)
	void OnStartDrawingObject(FSketchbookPencilDrawObjectParams DrawObjectParams){}

	UFUNCTION(BlueprintEvent)
	void OnMoveTowardsNextDrawable(){}

	UFUNCTION(BlueprintEvent)
	void OnReachedNextDrawable(){}

	UFUNCTION(BlueprintEvent)
	void OnFinishedDrawingPropGroup(){}

	UFUNCTION(BlueprintEvent)
	void OnFinishedDrawingObject(){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(EditInstanceOnly)
	UHazeAudioEmitter TipEmitter;

	UPROPERTY(EditInstanceOnly)
	UHazeAudioEmitter EraserEmitter;

	UPROPERTY(BlueprintReadOnly)
	ASketchbookPencil Pencil;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Pencil = Cast<ASketchbookPencil>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		float X;
		float Y_;
		FVector2D Previous;
		Audio::GetScreenPositionRelativePanningValue(TipEmitter.AudioComponent.WorldLocation, Previous, X, Y_);	

		TipEmitter.SetRTPC(Audio::Rtpc_SpeakerPanning_LR, X, 0.0);
		EraserEmitter.SetRTPC(Audio::Rtpc_SpeakerPanning_LR, X, 0);
	}
}