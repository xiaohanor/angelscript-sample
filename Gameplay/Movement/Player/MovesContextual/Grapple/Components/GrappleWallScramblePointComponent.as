
UCLASS(Meta = (EditorSpriteTexture = "/Game/Gameplay/Movement/ContextualMoves/ContextualMovesEditorTexture/WallRunPointIconBillboardGradient.WallRunPointIconBillboardGradient", EditorSpriteOffset="X=0 Y=0 Z=0"))
class UGrappleWallScramblePointComponent : UGrapplePointBaseComponent
{
	default TargetableCategory = n"ContextualMoves";
	default GrappleType = EGrapplePointVariations::WallScramblePoint;
	default UsableByPlayers = EHazeSelectPlayer::Both;

	UPROPERTY(EditAnywhere)
	float LaunchVelocity = 2500.0;

	UPROPERTY(EditAnywhere)
	UPlayerWallScrambleSettings Settings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
	}
}
