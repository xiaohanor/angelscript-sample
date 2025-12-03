UCLASS(Abstract)
class APrisonBossBrainNeuronManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	TArray<APrisonBossBrainNeuron> Neurons;
	TArray<UMaterialInstanceDynamic> NeuronMaterialInstances;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike MagnetBlastTimeLike;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike MagnetStunnedTimeLike;

	bool bMagnetStunned = false;

	UPROPERTY(EditAnywhere, Category = "MagnetBlast")
	float MagnetBlastPulseSpeed = 1000.0;
	
	UPROPERTY(EditAnywhere, Category = "MagnetBlast")
	float MagnetBlastPulseTiling = 0.01;

	UPROPERTY(EditAnywhere, Category = "MagnetBlast")
	FLinearColor MagnetBlastColor;

	UPROPERTY(EditAnywhere, Category = "MagnetBlast")
	FLinearColor MagnetBlastPulseColor;

	UPROPERTY(EditAnywhere, Category = "MagnetStunned")
	float MagnetStunnedPulseSpeed = 2.0;

	UPROPERTY(EditAnywhere, Category = "MagnetStunned")
	float MagnetStunnedPulseTiling = 0.1;

	UPROPERTY(EditAnywhere, Category = "MagnetStunned")
	FLinearColor MagnetStunnedColor;

	UPROPERTY(EditAnywhere, Category = "MagnetStunned")
	FLinearColor MagnetStunnedPulseColor;

	float DefaultPulseSpeed;
	float DefaultPulseTiling;
	FLinearColor DefaultColor;
	FLinearColor DefaultPulseColor;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Neurons = TListedActors<APrisonBossBrainNeuron>().Array;
		for (APrisonBossBrainNeuron Neuron : Neurons)
		{
			UMaterialInstanceDynamic Mat = Neuron.NeuronMeshComp.CreateDynamicMaterialInstance(0, Neuron.NeuronMeshComp.Materials[0]);
			NeuronMaterialInstances.Add(Mat);
		}

		DefaultPulseSpeed = NeuronMaterialInstances[0].GetScalarParameterValue(n"PulseSpeed");
		DefaultPulseTiling = NeuronMaterialInstances[0].GetScalarParameterValue(n"PulseTiling");
		DefaultColor = NeuronMaterialInstances[0].GetVectorParameterValue(n"Color");
		DefaultPulseColor = NeuronMaterialInstances[0].GetVectorParameterValue(n"PulseColor");

		MagnetBlastTimeLike.BindUpdate(this, n"UpdateMagnetBlast");
		MagnetBlastTimeLike.BindFinished(this, n"FinishMagnetBlast");

		MagnetStunnedTimeLike.BindUpdate(this, n"UpdateMagnetStunned");
		MagnetStunnedTimeLike.BindFinished(this, n"FinishMagnetStunned");
	}

	UFUNCTION(DevFunction)
	void MagnetBlasted()
	{
		MagnetBlastTimeLike.PlayFromStart();

		for (UMaterialInstanceDynamic NeuronMaterialInstance : NeuronMaterialInstances)
		{
			NeuronMaterialInstance.SetScalarParameterValue(n"PulseSpeed", MagnetBlastPulseSpeed);
			NeuronMaterialInstance.SetScalarParameterValue(n"PulseTiling", MagnetBlastPulseTiling);
		}
	}

	UFUNCTION()
	private void UpdateMagnetBlast(float CurValue)
	{
		for (UMaterialInstanceDynamic NeuronMaterialInstance : NeuronMaterialInstances)
		{
			FLinearColor Color = Math::Lerp(DefaultColor, MagnetBlastColor, CurValue);
			FLinearColor PulseColor = Math::Lerp(DefaultPulseColor, MagnetBlastPulseColor, CurValue);

			NeuronMaterialInstance.SetVectorParameterValue(n"Color", Color);
			NeuronMaterialInstance.SetVectorParameterValue(n"PulseColor", PulseColor);
		}
	}

	UFUNCTION()
	private void FinishMagnetBlast()
	{
		for (UMaterialInstanceDynamic NeuronMaterialInstance : NeuronMaterialInstances)
		{
			NeuronMaterialInstance.SetScalarParameterValue(n"PulseSpeed", DefaultPulseSpeed);
			NeuronMaterialInstance.SetScalarParameterValue(n"PulseTiling", DefaultPulseTiling);
		}

		if (bMagnetStunned)
		{
			MagnetStunnedTimeLike.PlayFromStart();
		}
	}

	UFUNCTION()
	void MagnetStunned()
	{
		bMagnetStunned = true;
	}

	UFUNCTION()
	void UnStunned()
	{
		bMagnetStunned = false;
		MagnetStunnedTimeLike.ReverseFromEnd();

		for (UMaterialInstanceDynamic NeuronMaterialInstance : NeuronMaterialInstances)
		{
			NeuronMaterialInstance.SetScalarParameterValue(n"PulseSpeed", DefaultPulseSpeed);
			NeuronMaterialInstance.SetScalarParameterValue(n"PulseTiling", DefaultPulseTiling);
		}
	}

	UFUNCTION(DevFunction)
	void MagnetStun()
	{
		MagnetStunnedTimeLike.PlayFromStart();

		for (UMaterialInstanceDynamic NeuronMaterialInstance : NeuronMaterialInstances)
		{
			NeuronMaterialInstance.SetScalarParameterValue(n"PulseSpeed", MagnetStunnedPulseSpeed);
			NeuronMaterialInstance.SetScalarParameterValue(n"PulseTiling", MagnetStunnedPulseTiling);
		}
	}

	UFUNCTION()
	private void UpdateMagnetStunned(float CurValue)
	{
		for (UMaterialInstanceDynamic NeuronMaterialInstance : NeuronMaterialInstances)
		{
			FLinearColor Color = Math::Lerp(DefaultColor, MagnetStunnedColor, CurValue);
			FLinearColor PulseColor = Math::Lerp(DefaultPulseColor, MagnetStunnedPulseColor, CurValue);

			NeuronMaterialInstance.SetVectorParameterValue(n"Color", Color);
			NeuronMaterialInstance.SetVectorParameterValue(n"PulseColor", PulseColor);
		}
	}

	UFUNCTION()
	private void FinishMagnetStunned()
	{

	}
}