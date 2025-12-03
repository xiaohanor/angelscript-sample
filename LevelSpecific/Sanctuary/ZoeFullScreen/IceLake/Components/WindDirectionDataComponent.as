UCLASS(Abstract)
class UWindDirectionDataComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	UWindDirectionSettings Settings;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem WindNiagara_Sys;
}