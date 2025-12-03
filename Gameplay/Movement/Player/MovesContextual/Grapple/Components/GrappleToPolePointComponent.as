
UCLASS(Meta = (EditorSpriteTexture = "/Game/Gameplay/Movement/ContextualMoves/ContextualMovesEditorTexture/GrapplePointIconBillboardGradient.GrapplePointIconBillboardGradient", EditorSpriteOffset="X=0 Y=0 Z=65"))
class UGrappleToPolePointComponent : UGrapplePointBaseComponent
{
	default TargetableCategory = n"ContextualMoves";
	default GrappleType = EGrapplePointVariations::GrappleToPolePoint;
	default UsableByPlayers = EHazeSelectPlayer::Both;

	UPROPERTY(NotVisible)
	APoleClimbActor PoleActor;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Super::ConstructionScript();

		if(PoleActor == nullptr)
		{
			APoleClimbActor CheckIfOwnerIsAPole = Cast<APoleClimbActor>(Owner);

			if(CheckIfOwnerIsAPole != nullptr)
				PoleActor = CheckIfOwnerIsAPole;
		}
	}

	void SetPoleReference(APoleClimbActor Pole)
	{
		PoleActor = Pole;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
	}
}