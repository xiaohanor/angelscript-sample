#if !RELEASE
namespace DevTogglesSketchbook
{
	const FHazeDevToggleBool DrawWordBounds;
};
#endif

UCLASS(NotBlueprintable)
class USketchbookPencilSentenceComponent : UActorComponent
{
	private ASketchbookPencil Pencil;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Pencil = Cast<ASketchbookPencil>(Owner);

#if !RELEASE
		DevTogglesSketchbook::DrawWordBounds.MakeVisible();
#endif
	}
};