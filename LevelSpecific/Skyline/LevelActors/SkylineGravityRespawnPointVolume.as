class ASkylineGravityRespawnPointVolume : ARespawnPointVolume
{
	default PrimaryActorTick.bStartWithTickEnabled = false;
	default bTriggerForMio = true;
	default bTriggerForZoe = false;

	UPROPERTY(DefaultComponent)
	USkylineGravityRespawnPointVolumeVisualizerComponent VisualizerComponent;

	bool bMioInsideWithWrongGravity = false;

	protected bool ShouldPlayerStateAllowTrigger(AHazePlayerCharacter Player) const override
	{
		return true;
	}

	protected void ReceiveBeginOverlap(AActor OtherActor) override
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
		if (!Player.IsMio())
			return;

		if (Player.GetGravityDirection().DotProduct(-ActorUpVector) < 0.99)
		{
			bMioInsideWithWrongGravity = true;
			SetActorTickEnabled(true);
			return;
		}

		Super::ReceiveBeginOverlap(OtherActor);
	}

	protected void ReceiveEndOverlap(AActor OtherActor) override
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
		if (!Player.IsMio())
			return;

		bMioInsideWithWrongGravity = false;
		SetActorTickEnabled(false);

		Super::ReceiveEndOverlap(OtherActor);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bMioInsideWithWrongGravity)
		{
			if (Game::Mio.GetGravityDirection().DotProduct(-ActorUpVector) >= 0.99)
			{
				ReceiveBeginOverlap(Game::Mio);
				bMioInsideWithWrongGravity = false;
				SetActorTickEnabled(false);
			}
		}
		else
		{
			SetActorTickEnabled(false);
		}
	}
}

class USkylineGravityRespawnPointVolumeVisualizerComponent : USceneComponent
{
	default bIsEditorOnly = true;
}

#if EDITOR
class USkylineGravityRespawnPointVolumeVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = USkylineGravityRespawnPointVolumeVisualizerComponent;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
		auto RespawnVolume = Cast<ASkylineGravityRespawnPointVolume>(Component.Owner);
		if (RespawnVolume == nullptr)
			return;

		DrawArrow(RespawnVolume.ActorLocation,
			RespawnVolume.ActorLocation + -RespawnVolume.ActorUpVector * 250.0,
			FLinearColor::Yellow,
			20.0,
			5.f
		);
    }   
} 
#endif