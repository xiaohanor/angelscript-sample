#if EDITOR
class USketchbookPencilProjectionTemporalLogComponent : UHazeTemporalLogScrubbableComponent
{
	private ASketchbookPencil Pencil;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Pencil = Cast<ASketchbookPencil>(Owner);	
	}

	UFUNCTION(BlueprintOverride)
	void OnTemporalLogScrubbedToFrame(UHazeTemporalLog Log, int LogFrameNumber)
	{
		if(Pencil != nullptr)
			Pencil.UpdateProjectionMatrix();
	}
}
#endif