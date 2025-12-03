UCLASS(Abstract)
class ACoastWaterskiAttachPointActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCoastWaterskiAttachPointComponent AttachPointComponent;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UGrapplePointDrawComponent DrawComp;
#endif
}

UCLASS(NotBlueprintable, NotPlaceable, Meta = (EditorSpriteTexture = "/Game/Gameplay/Movement/ContextualMoves/ContextualMovesEditorTexture/GrapplePointIconBillboardGradient.GrapplePointIconBillboardGradient", EditorSpriteOffset="X=0 Y=0 Z=65"))
class UCoastWaterskiAttachPointComponent : UContextualMovesTargetableComponent
{

}